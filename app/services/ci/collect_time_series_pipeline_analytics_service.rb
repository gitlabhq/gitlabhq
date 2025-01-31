# frozen_string_literal: true

module Ci
  class CollectTimeSeriesPipelineAnalyticsService < CollectPipelineAnalyticsServiceBase
    extend ::Gitlab::Utils::Override

    include Gitlab::InternalEventsTracking

    VALID_TIME_SERIES_PERIODS = %i[day week month].freeze

    attr_reader :time_series_period

    def initialize(from_time:, to_time:, time_series_period: :day, **kwargs)
      from_time = to_utc(from_time) if from_time.present?
      to_time = to_utc(to_time) if to_time.present?

      super(from_time: from_time, to_time: to_time, **kwargs)

      @time_series_period = time_series_period
    end

    private

    override :validate_arguments
    def validate_arguments
      if VALID_TIME_SERIES_PERIODS.exclude?(time_series_period)
        return ServiceResponse.error(message: 'invalid time series period')
      end

      super
    end

    override :fetch_response
    def fetch_response
      time_series = create_empty_time_series
      query = base_query

      if status_groups.any?
        calculate_time_series_count(query, time_series)
        calculate_time_series_status_group_counts(query, time_series)
      end

      calculate_time_series_duration_percentiles(query, time_series)
      collect_metrics

      ServiceResponse.success(payload: {
        time_series: time_series.map do |date, value|
          { label: date, **value }
        end
      })
    rescue ::ClickHouse::Client::DatabaseError => e
      ServiceResponse.error(message: e.message)
    end

    def timespan_bin_query_function(query)
      query.timestamp_bin_function(time_series_period)
    end

    def calculate_time_series_count(query, time_series)
      return if status_groups.exclude?(:any)

      all_query = query
        .select(timespan_bin_query_function(query), query.count_pipelines_function.as('all'))
        .group_by_timestamp_bin

      all_count_result =
        execute_select_query(all_query)
          .to_h do |entry|
            [parse_in_utc(entry[:timestamp]), { count: { any: entry[:all] } }]
          end

      time_series.deep_merge!(all_count_result)
    end

    def calculate_time_series_status_group_counts(query, time_series)
      return unless status_groups.intersect?(STATUS_GROUPS)

      query = query
        .select(timespan_bin_query_function(query), :status, query.count_pipelines_function.as('count'))
        .by_status(selected_statuses)
        .group_by_timestamp_bin
        .group_by_status

      # Produce a chronological set of hashes
      # such as `{ Time.utc(2023, 1, 1) => { count: { success: 1, failed: 0, other: 1, any: 3 } }`
      counts_by_timestamp =
        execute_select_query(query)
          .group_by { |entry| parse_in_utc(entry[:timestamp]) }
          .transform_values { |counts_by_status| { count: group_and_sum_counts(counts_by_status) } }

      time_series.deep_merge!(counts_by_timestamp)
    end

    def calculate_time_series_duration_percentiles(query, time_series)
      return if duration_percentiles.empty?

      duration_by_date_query = query.select(
        timespan_bin_query_function(query),
        *duration_percentiles.map { |p| query.duration_quantile_function(p) }
      ).group_by_timestamp_bin

      time_series.deep_merge!(
        execute_select_query(duration_by_date_query)
          .group_by { |entry| parse_in_utc(entry[:timestamp]) }
          .transform_values { |hash| hash.sole.excluding(:timestamp) } # Keep only percentiles
          .transform_values do |percentiles_by_date|
            { duration_statistics: round_percentiles(percentiles_by_date) }
          end
      )
    end

    def beginning_of_time_window
      case time_series_period
      when :week
        from_time.beginning_of_week
      when :month
        from_time.beginning_of_month
      else
        from_time.beginning_of_day
      end
    end

    def next_time_window_period(time)
      case time_series_period
      when :week
        time.next_week
      when :month
        time.next_month
      else
        time.tomorrow
      end
    end

    def create_empty_time_series
      current = beginning_of_time_window

      {}.tap do |time_series|
        while current < to_time
          time_series[current] = {
            count: status_groups.index_with(0),
            duration_statistics: round_percentiles(duration_percentile_symbols.index_with(0))
          }.compact_blank

          current = next_time_window_period(current)
        end
      end
    end

    def round_percentiles(percentiles_by_date)
      percentiles_by_date.transform_values { |interval| interval.to_f.round(3).seconds }
    end

    def to_utc(timestamp)
      timestamp.change(offset: 0).utc
    end

    def parse_in_utc(timestamp)
      to_utc(Time.parse(timestamp)) # rubocop:disable Rails/TimeZone -- false positive, to_utc takes care of this
    end

    def group_and_sum_counts(counts_by_status_and_time)
      # This method receives an array of hashes representing counts per job status per day,
      # e.g. [
      #   { :timestamp => "2023-01-01 00:00:00", :status => "canceled", :count => 2 },
      #   { :timestamp => "2023-01-01 00:00:00", :status => "skipped", :count => 1 },
      #   { :timestamp => "2023-01-01 00:00:00", :status => "success", :count => 2 }
      # ] and returns a hash synthesizing the information as
      # { 2023-01-01 00:00:00 UTC => {:count => { :other=>3, :success=>2 } } }
      counts_by_status_and_time
        .to_h { |h| h.slice(:status, :count).values }                 # Create hash from status to count
        .group_by { |status, _count| STATUS_TO_STATUS_GROUP[status] } # Group by status group
        .transform_values { |pairs| pairs.sum(&:last) }               # Sum counts from all statuses in group
    end

    def execute_select_query(query)
      ::ClickHouse::Client.select(query.to_sql, :main).map(&:symbolize_keys)
    end

    def collect_metrics
      track_internal_event(
        'collect_time_series_pipeline_analytics',
        project: project,
        user: current_user,
        additional_properties: { property: time_series_period.to_s }
      )
    end
  end
end

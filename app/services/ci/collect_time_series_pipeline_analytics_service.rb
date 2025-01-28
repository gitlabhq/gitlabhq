# frozen_string_literal: true

module Ci
  class CollectTimeSeriesPipelineAnalyticsService < CollectPipelineAnalyticsServiceBase
    extend ::Gitlab::Utils::Override

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

      calculate_time_series_duration_percentiles(query, time_series)

      ServiceResponse.success(payload: {
        time_series: time_series.map do |date, value|
          { label: date, **value }
        end
      })
    end

    def timespan_bin_query_function(query)
      query.timestamp_bin_function(time_series_period)
    end

    def calculate_time_series_duration_percentiles(query, time_series)
      return if duration_percentiles.empty?

      duration_by_date_query = query.select(
        timespan_bin_query_function(query),
        *duration_percentiles.map { |p| query.duration_quantile_function(p) }
      ).group_by_timestamp_bin
      duration_by_date_result = ::ClickHouse::Client.select(duration_by_date_query.to_sql, :main)

      time_series.deep_merge!(
        duration_by_date_result
          .map(&:symbolize_keys)
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
  end
end

# frozen_string_literal: true

module Ci
  class CollectPipelineAnalyticsService
    STATUS_GROUP_TO_STATUSES = { success: %w[success], failed: %w[failed], other: %w[canceled skipped] }.freeze
    STATUS_GROUPS = STATUS_GROUP_TO_STATUSES.keys.freeze
    STATUS_TO_STATUS_GROUP = STATUS_GROUP_TO_STATUSES.flat_map { |k, v| v.product([k]) }.to_h

    ALLOWED_PERCENTILES = [50, 75, 90, 95, 99].freeze

    def initialize(
      current_user:, project:, from_time:, to_time:,
      source: nil, ref: nil, status_groups: [:any], duration_percentiles: []
    )
      @current_user = current_user
      @project = project
      @status_groups = status_groups
      @source = source
      @ref = ref
      @duration_percentiles = duration_percentiles
      @from_time = from_time || 1.week.ago.utc
      @to_time = to_time || Time.now.utc
    end

    def execute
      return ServiceResponse.error(message: 'Project must be specified') unless @project

      unless ::Gitlab::ClickHouse.configured?
        return ServiceResponse.error(message: 'ClickHouse database is not configured')
      end

      return ServiceResponse.error(message: 'Not allowed') unless allowed?

      error_message = clickhouse_model.validate_time_window(@from_time, @to_time)
      return ServiceResponse.error(message: error_message) if error_message

      ServiceResponse.success(payload: { aggregate: calculate_aggregate })
    end

    private

    def allowed?
      @current_user&.can?(:read_ci_cd_analytics, @project)
    end

    def clickhouse_model
      if ::ClickHouse::Models::Ci::FinishedPipelinesHourly.time_window_valid?(@from_time, @to_time)
        return ::ClickHouse::Models::Ci::FinishedPipelinesHourly
      end

      ::ClickHouse::Models::Ci::FinishedPipelinesDaily
    end

    def calculate_aggregate
      query = clickhouse_model.for_project(@project).within_dates(@from_time, @to_time)
      query = query.for_source(@source) if @source
      query = query.for_ref(@ref) if @ref
      result = {}

      if @status_groups.any?
        result[:count] = @status_groups.index_with(0)
        calculate_aggregate_count(query, result[:count])
        calculate_aggregate_status_group_counts(query, result[:count])
      end

      calculate_aggregate_duration_percentiles(query, result)

      result
    end

    def calculate_aggregate_count(query, result)
      return if @status_groups.exclude?(:any)

      all_query = query.select(query.count_pipelines_function.as('all'))
      result[:any] = ::ClickHouse::Client.select(all_query.to_sql, :main).first['all']
    end

    def calculate_aggregate_status_group_counts(query, result)
      return unless @status_groups.intersect?(STATUS_GROUPS)

      query = query
        .select(:status, query.count_pipelines_function.as('count'))
        .by_status(@status_groups.flat_map(&STATUS_GROUP_TO_STATUSES).compact)
        .group_by_status

      result_by_status = ::ClickHouse::Client.select(query.to_sql, :main).map(&:values).to_h
      result_by_status.each_pair { |status, count| result[STATUS_TO_STATUS_GROUP[status]] += count }
    end

    def calculate_aggregate_duration_percentiles(query, result)
      return if allowed_duration_percentiles.empty?

      duration_query = query.select(*allowed_duration_percentiles.map { |p| query.duration_quantile_function(p) })
      duration_result = ::ClickHouse::Client.select(duration_query.to_sql, :main)
      result[:duration_statistics] = duration_result.first.symbolize_keys.transform_values do |interval|
        interval ? interval.to_f.round(3).seconds : nil
      end
    end

    def allowed_duration_percentiles
      @duration_percentiles & ALLOWED_PERCENTILES
    end
  end
end

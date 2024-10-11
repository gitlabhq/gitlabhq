# frozen_string_literal: true

module Ci
  class CollectPipelineAnalyticsService
    STATUS_GROUP_TO_STATUSES = { success: %w[success], failed: %w[failed], other: %w[canceled skipped] }.freeze
    STATUS_GROUPS = STATUS_GROUP_TO_STATUSES.keys.freeze
    STATUS_TO_STATUS_GROUP = STATUS_GROUP_TO_STATUSES.flat_map { |k, v| v.product([k]) }.to_h

    def initialize(current_user:, project:, from_time:, to_time:, source: nil, ref: nil, status_groups: [:all])
      @current_user = current_user
      @project = project
      @status_groups = status_groups
      @source = source
      @ref = ref
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
      result = @status_groups.index_with(0)

      query = clickhouse_model
        .for_project(@project)
        .within_dates(@from_time, @to_time)

      query = query.for_source(@source) if @source
      query = query.for_ref(@ref) if @ref

      if @status_groups.include?(:all)
        all_query = query.select(query.count_pipelines_function.as('all'))
        result[:all] = ::ClickHouse::Client.select(all_query.to_sql, :main).first['all']
      end

      if @status_groups.intersect?(STATUS_GROUPS)
        query = query
          .select(:status, query.count_pipelines_function.as('count'))
          .by_status(@status_groups.flat_map(&STATUS_GROUP_TO_STATUSES).compact)
          .group_by_status

        result_by_status = ::ClickHouse::Client.select(query.to_sql, :main).map(&:values).to_h
        result_by_status.each_pair { |status, count| result[STATUS_TO_STATUS_GROUP[status]] += count }
      end

      result
    end
  end
end

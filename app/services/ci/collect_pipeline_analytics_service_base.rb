# frozen_string_literal: true

module Ci
  class CollectPipelineAnalyticsServiceBase
    STATUS_GROUP_TO_STATUSES = { success: %w[success], failed: %w[failed], other: %w[canceled skipped] }.freeze
    STATUS_GROUPS = STATUS_GROUP_TO_STATUSES.keys.freeze
    STATUS_TO_STATUS_GROUP = STATUS_GROUP_TO_STATUSES.flat_map { |k, v| v.product([k]) }.to_h

    ALLOWED_PERCENTILES = [50, 75, 90, 95, 99].freeze

    attr_reader :current_user, :project, :from_time, :to_time, :source, :ref, :status_groups, :duration_percentiles

    def initialize(
      current_user:, project:, from_time:, to_time:,
      source: nil, ref: nil, status_groups: [:any], duration_percentiles: []
    )
      @current_user = current_user
      @project = project
      @from_time = from_time || 1.week.ago.utc
      @to_time = to_time || Time.now.utc
      @status_groups = status_groups
      @source = source
      @ref = ref
      @duration_percentiles = duration_percentiles
    end

    def execute
      error_response = validate_arguments
      return error_response if error_response

      unless ::Gitlab::ClickHouse.configured?
        return ServiceResponse.error(message: 'ClickHouse database is not configured')
      end

      fetch_response
    end

    private

    def allowed?
      current_user&.can?(:read_ci_cd_analytics, project)
    end

    def clickhouse_model
      if ::ClickHouse::Models::Ci::FinishedPipelinesHourly.time_window_valid?(from_time, to_time)
        return ::ClickHouse::Models::Ci::FinishedPipelinesHourly
      end

      ::ClickHouse::Models::Ci::FinishedPipelinesDaily
    end

    def base_query
      query = clickhouse_model.for_project(project).within_dates(from_time, to_time)
      query = query.for_source(source) if source
      query = query.for_ref(ref) if ref

      query
    end

    def duration_percentile_symbols
      duration_percentiles.map { |p| :"p#{p}" }
    end

    def selected_statuses
      status_groups.flat_map(&STATUS_GROUP_TO_STATUSES).compact
    end

    def validate_arguments
      if (duration_percentiles & ALLOWED_PERCENTILES) != duration_percentiles
        return ServiceResponse.error(message: 'Invalid duration percentiles specified')
      end

      return ServiceResponse.error(message: 'Project must be specified') if project.nil?
      return ServiceResponse.error(message: 'Not allowed') unless allowed?
      return ServiceResponse.error(message: 'Invalid time window') if from_time > to_time

      error_message = clickhouse_model.validate_time_window(from_time, to_time)
      ServiceResponse.error(message: error_message) if error_message
    end

    def fetch_response
      raise NotImplementedError, "#{self.class} must implement `#{__method__}`"
    end
  end
end

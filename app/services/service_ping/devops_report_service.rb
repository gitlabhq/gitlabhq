# frozen_string_literal: true

module ServicePing
  class DevopsReportService
    METRICS = %w[leader_issues instance_issues percentage_issues leader_notes instance_notes
                 percentage_notes leader_milestones instance_milestones percentage_milestones
                 leader_boards instance_boards percentage_boards leader_merge_requests
                 instance_merge_requests percentage_merge_requests leader_ci_pipelines
                 instance_ci_pipelines percentage_ci_pipelines leader_environments instance_environments
                 percentage_environments leader_deployments instance_deployments percentage_deployments
                 leader_projects_prometheus_active instance_projects_prometheus_active
                 percentage_projects_prometheus_active leader_service_desk_issues instance_service_desk_issues
                 percentage_service_desk_issues].freeze

    def initialize(data)
      @data = data
    end

    def execute
      metrics = @data['conv_index'] || @data['dev_ops_score'] # leaving dev_ops_score here, as the data comes from the gitlab-version-com

      return unless metrics.except('usage_data_id').present?

      DevOpsReport::Metric.create!(
        metrics.slice(*METRICS)
      )
    end
  end
end

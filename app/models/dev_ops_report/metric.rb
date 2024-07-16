# frozen_string_literal: true

module DevOpsReport
  class Metric < ApplicationRecord
    include Presentable

    self.table_name = 'conversational_development_index_metrics'

    METRICS = %w[leader_issues instance_issues percentage_issues leader_notes instance_notes
      percentage_notes leader_milestones instance_milestones percentage_milestones
      leader_boards instance_boards percentage_boards leader_merge_requests
      instance_merge_requests percentage_merge_requests leader_ci_pipelines
      instance_ci_pipelines percentage_ci_pipelines leader_environments instance_environments
      percentage_environments leader_deployments instance_deployments percentage_deployments
      leader_projects_prometheus_active instance_projects_prometheus_active
      percentage_projects_prometheus_active leader_service_desk_issues instance_service_desk_issues
      percentage_service_desk_issues].freeze

    METRICS.each do |metric_name|
      validates metric_name, presence: true, numericality: { greater_than_or_equal_to: 0 }
    end

    def instance_score(feature)
      self["instance_#{feature}"]
    end

    def leader_score(feature)
      self["leader_#{feature}"]
    end

    def percentage_score(feature)
      self["percentage_#{feature}"]
    end
  end
end

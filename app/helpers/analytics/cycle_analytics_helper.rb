# frozen_string_literal: true

module Analytics
  module CycleAnalyticsHelper
    def cycle_analytics_default_stage_config
      Gitlab::Analytics::CycleAnalytics::DefaultStages.all.map do |stage_params|
        Analytics::CycleAnalytics::StagePresenter.new(stage_params)
      end
    end

    def cycle_analytics_initial_data(project, group = nil)
      base_data = { project_id: project.id, group_path: project.group&.path, request_path: project_cycle_analytics_path(project), full_path: project.full_path }
      svgs = { empty_state_svg_path: image_path("illustrations/analytics/cycle-analytics-empty-chart.svg"), no_data_svg_path: image_path("illustrations/analytics/cycle-analytics-empty-chart.svg"), no_access_svg_path: image_path("illustrations/analytics/no-access.svg") }
      api_paths = group.present? ? cycle_analytics_group_api_paths(group) : cycle_analytics_project_api_paths(project)

      base_data.merge(svgs, api_paths)
    end

    private

    def cycle_analytics_group_api_paths(group)
      { milestones_path: group_milestones_path(group, format: :json), labels_path: group_labels_path(group, format: :json), group_path: group_path(group), group_id: group&.id }
    end

    def cycle_analytics_project_api_paths(project)
      { milestones_path: project_milestones_path(project, format: :json), labels_path: project_labels_path(project, format: :json), group_path: project.parent&.path, group_id: project.parent&.id }
    end
  end
end

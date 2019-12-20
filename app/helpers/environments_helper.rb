# frozen_string_literal: true

module EnvironmentsHelper
  prepend_if_ee('::EE::EnvironmentsHelper') # rubocop: disable Cop/InjectEnterpriseEditionModule

  def environments_list_data
    {
      endpoint: project_environments_path(@project, format: :json)
    }
  end

  def environments_folder_list_view_data
    {
      "endpoint" => folder_project_environments_path(@project, @folder, format: :json),
      "folder-name" => @folder,
      "can-read-environment" => can?(current_user, :read_environment, @project).to_s
    }
  end

  def metrics_data(project, environment)
    {
      "settings-path" => edit_project_service_path(project, 'prometheus'),
      "clusters-path" => project_clusters_path(project),
      "current-environment-name": environment.name,
      "documentation-path" => help_page_path('administration/monitoring/prometheus/index.md'),
      "empty-getting-started-svg-path" => image_path('illustrations/monitoring/getting_started.svg'),
      "empty-loading-svg-path" => image_path('illustrations/monitoring/loading.svg'),
      "empty-no-data-svg-path" => image_path('illustrations/monitoring/no_data.svg'),
      "empty-no-data-small-svg-path" => image_path('illustrations/chart-empty-state-small.svg'),
      "empty-unable-to-connect-svg-path" => image_path('illustrations/monitoring/unable_to_connect.svg'),
      "metrics-endpoint" => additional_metrics_project_environment_path(project, environment, format: :json),
      "dashboard-endpoint" => metrics_dashboard_project_environment_path(project, environment, format: :json),
      "deployments-endpoint" => project_environment_deployments_path(project, environment, format: :json),
      "environments-endpoint": project_environments_path(project, format: :json),
      "project-path" => project_path(project),
      "tags-path" => project_tags_path(project),
      "has-metrics" => "#{environment.has_metrics?}",
      "prometheus-status" => "#{environment.prometheus_status}",
      "external-dashboard-url" => project.metrics_setting_external_dashboard_url
    }
  end
end

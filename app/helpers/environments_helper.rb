# frozen_string_literal: true

module EnvironmentsHelper
  include ActionView::Helpers::AssetUrlHelper

  def environments_list_data
    {
      endpoint: project_environments_path(@project, format: :json)
    }
  end

  def environments_folder_list_view_data(project, folder)
    {
      "endpoint" => folder_project_environments_path(project, folder, format: :json),
      "folder_name" => folder,
      "project_path" => project.full_path,
      "help_page_path" => help_page_path("ci/environments/index"),
      "can_read_environment" => can?(current_user, :read_environment, @project).to_s
    }
  end

  def custom_metrics_available?(project)
    can?(current_user, :admin_project, project)
  end

  def metrics_data(project, environment)
    return {} if Feature.enabled?(:remove_monitor_metrics)

    metrics_data = {}
    metrics_data.merge!(project_metrics_data(project)) if project
    metrics_data.merge!(environment_metrics_data(environment)) if environment
    metrics_data.merge!(project_and_environment_metrics_data(project, environment)) if project && environment
    metrics_data.merge!(static_metrics_data)

    metrics_data
  end

  def can_destroy_environment?(environment)
    can?(current_user, :destroy_environment, environment)
  end

  private

  def project_metrics_data(project)
    return {} unless project

    {
      'settings_path' => edit_project_settings_integration_path(project, 'prometheus'),
      'clusters_path' => project_clusters_path(project),
      'default_branch' => project.default_branch,
      'project_path' => project_path(project),
      'tags_path' => project_tags_path(project),
      'custom_metrics_path' => project_prometheus_metrics_path(project),
      'validate_query_path' => validate_query_project_prometheus_metrics_path(project),
      'custom_metrics_available' => custom_metrics_available?(project).to_s
    }
  end

  def environment_metrics_data(environment)
    return {} unless environment

    {
      'current_environment_name' => environment.name,
      'has_metrics' => environment.has_metrics?.to_s,
      'environment_state' => environment.state.to_s
    }
  end

  def project_and_environment_metrics_data(project, environment)
    return {} unless project && environment

    {
      'deployments_endpoint' => project_environment_deployments_path(project, environment, format: :json),
      'operations_settings_path' => project_settings_operations_path(project),
      'can_access_operations_settings' => can?(current_user, :admin_operations, project).to_s
    }
  end

  def static_metrics_data
    {
      'documentation_path' => help_page_path('administration/monitoring/prometheus/index'),
      'add_dashboard_documentation_path' => help_page_path('operations/metrics/dashboards/index', anchor: 'add-a-new-dashboard-to-your-project')
    }
  end
end

EnvironmentsHelper.prepend_mod_with('EnvironmentsHelper')

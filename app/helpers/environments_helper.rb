# frozen_string_literal: true

module EnvironmentsHelper
  include ActionView::Helpers::AssetUrlHelper

  def environments_list_data
    {
      endpoint: project_environments_path(@project, format: :json)
    }
  end

  def environments_folder_list_view_data
    {
      "endpoint" => folder_project_environments_path(@project, @folder, format: :json),
      "folder_name" => @folder,
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
    metrics_data.merge!(environment_metrics_data(environment, project)) if environment
    metrics_data.merge!(project_and_environment_metrics_data(project, environment)) if project && environment
    metrics_data.merge!(static_metrics_data)

    metrics_data
  end

  def environment_logs_data(project, environment)
    {
      "environment_name": environment.name,
      "environments_path": api_v4_projects_environments_path(id: project.id),
      "environment_id": environment.id,
      "clusters_path": project_clusters_path(project, format: :json)
    }
  end

  def can_destroy_environment?(environment)
    can?(current_user, :destroy_environment, environment)
  end

  def environment_data(environment)
    Gitlab::Json.generate({
      id: environment.id,
      name: environment.name,
      external_url: environment.external_url
    })
  end

  private

  def project_metrics_data(project)
    return {} unless project

    {
      'settings_path' => edit_project_settings_integration_path(project, 'prometheus'),
      'clusters_path' => project_clusters_path(project),
      'dashboards_endpoint' => project_performance_monitoring_dashboards_path(project, format: :json),
      'default_branch' => project.default_branch,
      'project_path' => project_path(project),
      'tags_path' => project_tags_path(project),
      'external_dashboard_url' => project.metrics_setting_external_dashboard_url,
      'custom_metrics_path' => project_prometheus_metrics_path(project),
      'validate_query_path' => validate_query_project_prometheus_metrics_path(project),
      'custom_metrics_available' => custom_metrics_available?(project).to_s,
      'dashboard_timezone' => project.metrics_setting_dashboard_timezone.to_s.upcase
    }
  end

  def environment_metrics_data(environment, project = nil)
    return {} unless environment

    {
      'metrics_dashboard_base_path' => metrics_dashboard_base_path(environment, project),
      'current_environment_name' => environment.name,
      'has_metrics' => environment.has_metrics?.to_s,
      'environment_state' => environment.state.to_s
    }
  end

  def metrics_dashboard_base_path(environment, project)
    # This is needed to support our transition from environment scoped metric paths to project scoped.
    if project
      path = project_metrics_dashboard_path(project)

      return path if request.path.include?(path)
    end

    project_metrics_dashboard_path(project, environment: environment)
  end

  def project_and_environment_metrics_data(project, environment)
    return {} unless project && environment

    {
      'metrics_endpoint' => additional_metrics_project_environment_path(project, environment, format: :json),
      'dashboard_endpoint' => metrics_dashboard_project_environment_path(project, environment, format: :json),
      'deployments_endpoint' => project_environment_deployments_path(project, environment, format: :json),
      'operations_settings_path' => project_settings_operations_path(project),
      'can_access_operations_settings' => can?(current_user, :admin_operations, project).to_s,
      'panel_preview_endpoint' => project_metrics_dashboards_builder_path(project, format: :json)
    }
  end

  def static_metrics_data
    {
      'documentation_path' => help_page_path('administration/monitoring/prometheus/index.md'),
      'add_dashboard_documentation_path' => help_page_path('operations/metrics/dashboards/index.md', anchor: 'add-a-new-dashboard-to-your-project'),
      'empty_getting_started_svg_path' => image_path('illustrations/monitoring/getting_started.svg'),
      'empty_loading_svg_path' => image_path('illustrations/monitoring/loading.svg'),
      'empty_no_data_svg_path' => image_path('illustrations/monitoring/no_data.svg'),
      'empty_no_data_small_svg_path' => image_path('illustrations/chart-empty-state-small.svg'),
      'empty_unable_to_connect_svg_path' => image_path('illustrations/monitoring/unable_to_connect.svg'),
      'custom_dashboard_base_path' => Gitlab::Metrics::Dashboard::RepoDashboardFinder::DASHBOARD_ROOT
    }
  end
end

EnvironmentsHelper.prepend_mod_with('EnvironmentsHelper')

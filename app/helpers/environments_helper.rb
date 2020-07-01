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
      "folder-name" => @folder,
      "can-read-environment" => can?(current_user, :read_environment, @project).to_s
    }
  end

  def custom_metrics_available?(project)
    can?(current_user, :admin_project, project)
  end

  def metrics_data(project, environment)
    metrics_data = {}
    metrics_data.merge!(project_metrics_data(project)) if project
    metrics_data.merge!(environment_metrics_data(environment)) if environment
    metrics_data.merge!(project_and_environment_metrics_data(project, environment)) if project && environment
    metrics_data.merge!(static_metrics_data)

    metrics_data
  end

  def environment_logs_data(project, environment)
    {
      "environment-name": environment.name,
      "environments-path": project_environments_path(project, format: :json),
      "environment-id": environment.id,
      "cluster-applications-documentation-path" => help_page_path('user/clusters/applications.md', anchor: 'elastic-stack')
    }
  end

  def can_destroy_environment?(environment)
    can?(current_user, :destroy_environment, environment)
  end

  private

  def project_metrics_data(project)
    return {} unless project

    {
      'settings-path'               => edit_project_service_path(project, 'prometheus'),
      'clusters-path'               => project_clusters_path(project),
      'dashboards-endpoint'         => project_performance_monitoring_dashboards_path(project, format: :json),
      'default-branch'              => project.default_branch,
      'project-path'                => project_path(project),
      'tags-path'                   => project_tags_path(project),
      'external-dashboard-url'      => project.metrics_setting_external_dashboard_url,
      'custom-metrics-path'         => project_prometheus_metrics_path(project),
      'validate-query-path'         => validate_query_project_prometheus_metrics_path(project),
      'custom-metrics-available'    => "#{custom_metrics_available?(project)}",
      'prometheus-alerts-available' => "#{can?(current_user, :read_prometheus_alerts, project)}",
      'dashboard-timezone'          => project.metrics_setting_dashboard_timezone.to_s.upcase
    }
  end

  def environment_metrics_data(environment)
    return {} unless environment

    {
      'metrics-dashboard-base-path' => environment_metrics_path(environment),
      'current-environment-name'    => environment.name,
      'has-metrics'                 => "#{environment.has_metrics?}",
      'prometheus-status'           => "#{environment.prometheus_status}",
      'environment-state'           => "#{environment.state}"
    }
  end

  def project_and_environment_metrics_data(project, environment)
    return {} unless project && environment

    {
      'metrics-endpoint'     => additional_metrics_project_environment_path(project, environment, format: :json),
      'dashboard-endpoint'   => metrics_dashboard_project_environment_path(project, environment, format: :json),
      'deployments-endpoint' => project_environment_deployments_path(project, environment, format: :json),
      'alerts-endpoint'      => project_prometheus_alerts_path(project, environment_id: environment.id, format: :json)

    }
  end

  def static_metrics_data
    {
      'documentation-path'               => help_page_path('administration/monitoring/prometheus/index.md'),
      'empty-getting-started-svg-path'   => image_path('illustrations/monitoring/getting_started.svg'),
      'empty-loading-svg-path'           => image_path('illustrations/monitoring/loading.svg'),
      'empty-no-data-svg-path'           => image_path('illustrations/monitoring/no_data.svg'),
      'empty-no-data-small-svg-path'     => image_path('illustrations/chart-empty-state-small.svg'),
      'empty-unable-to-connect-svg-path' => image_path('illustrations/monitoring/unable_to_connect.svg'),
      'custom-dashboard-base-path'       => Metrics::Dashboard::CustomDashboardService::DASHBOARD_ROOT
    }
  end
end

EnvironmentsHelper.prepend_if_ee('::EE::EnvironmentsHelper')

# frozen_string_literal: true

module Projects::AlertManagementHelper
  def alert_management_data(current_user, project)
    {
      'project-path' => project.full_path,
      'enable-alert-management-path' => project_settings_operations_path(project, anchor: 'js-alert-management-settings'),
      'alerts-help-url' => help_page_url('operations/incident_management/alerts.md'),
      'populating-alerts-help-url' => help_page_url('operations/incident_management/integrations.md', anchor: 'configuration'),
      'empty-alert-svg-path' => image_path('illustrations/alert-management-empty-state.svg'),
      'user-can-enable-alert-management' => can?(current_user, :admin_operations, project).to_s,
      'alert-management-enabled' => alert_management_enabled?(project).to_s,
      'has-managed-prometheus' => has_managed_prometheus?(project).to_s,
      'text-query': params[:search],
      'assignee-username-query': params[:assignee_username]
    }
  end

  def alert_management_detail_data(project, alert_id)
    {
      'alert-id' => alert_id,
      'project-path' => project.full_path,
      'project-id' => project.id,
      'project-issues-path' => project_issues_path(project),
      'page' => 'OPERATIONS'
    }
  end

  private

  def has_managed_prometheus?(project)
    project.prometheus_integration&.prometheus_available? == true
  end

  def alert_management_enabled?(project)
    !!(
      project.alert_management_alerts.any? ||
      project.prometheus_integration_active? ||
      AlertManagement::HttpIntegrationsFinder.new(project, active: true).execute.any?
    )
  end
end

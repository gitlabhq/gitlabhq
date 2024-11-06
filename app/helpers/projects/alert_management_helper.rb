# frozen_string_literal: true

module Projects::AlertManagementHelper
  def alert_management_data(current_user, project)
    {
      'project-path' => project.full_path,
      'enable-alert-management-path' => project_settings_operations_path(
        project,
        anchor: 'js-alert-management-settings'
      ),
      'alerts-help-url' => help_page_url('operations/incident_management/alerts.md'),
      'populating-alerts-help-url' => help_page_url(
        'operations/incident_management/integrations.md',
        anchor: 'configuration'
      ),
      'empty-alert-svg-path' => image_path('illustrations/empty-state/empty-scan-alert-md.svg'),
      'user-can-enable-alert-management' => can?(current_user, :admin_operations, project).to_s,
      'alert-management-enabled' => alert_management_enabled?(project).to_s,
      'text-query': params[:search],
      'assignee-username-query': params[:assignee_username]
    }
  end

  def alert_management_detail_data(current_user, project, alert_id)
    {
      'alert-id' => alert_id,
      'project-path' => project.full_path,
      'project-id' => project.id,
      'project-issues-path' => project_issues_path(project),
      'project-alert-management-details-path' => details_project_alert_management_path(project, alert_id),
      'page' => 'OPERATIONS',
      'can-update' => can?(current_user, :update_alert_management_alert, project).to_s
    }
  end

  private

  def alert_management_enabled?(project)
    !!(
      project.alert_management_alerts.any? ||
      project.prometheus_integration_active? ||
      AlertManagement::HttpIntegrationsFinder.new(project, active: true).execute.any?
    )
  end
end

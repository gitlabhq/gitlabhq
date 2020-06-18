# frozen_string_literal: true

module Projects::AlertManagementHelper
  def alert_management_data(current_user, project)
    {
      'project-path' => project.full_path,
      'enable-alert-management-path' => edit_project_service_path(project, AlertsService),
      'empty-alert-svg-path' => image_path('illustrations/alert-management-empty-state.svg'),
      'user-can-enable-alert-management' => can?(current_user, :admin_project, project).to_s,
      'alert-management-enabled' => (!!project.alerts_service_activated?).to_s
    }
  end

  def alert_management_detail_data(project, alert_id)
    {
      'alert-id' => alert_id,
      'project-path' => project.full_path,
      'project-issues-path' => project_issues_path(project)
    }
  end
end

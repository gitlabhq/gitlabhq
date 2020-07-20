# frozen_string_literal: true

module Projects::AlertManagementHelper
  def alert_management_data(current_user, project)
    {
      'project-path' => project.full_path,
      'enable-alert-management-path' => project_settings_operations_path(project, anchor: 'js-alert-management-settings'),
      'populating-alerts-help-url' => help_page_url('user/project/operations/alert_management.html', anchor: 'enable-alert-management'),
      'empty-alert-svg-path' => image_path('illustrations/alert-management-empty-state.svg'),
      'user-can-enable-alert-management' => can?(current_user, :admin_operations, project).to_s,
      'alert-management-enabled' => alert_management_enabled?(project).to_s
    }
  end

  def alert_management_detail_data(project, alert_id)
    {
      'alert-id' => alert_id,
      'project-path' => project.full_path,
      'project-id' => project.id,
      'project-issues-path' => project_issues_path(project)
    }
  end

  private

  def alert_management_enabled?(project)
    !!(project.alerts_service_activated? || project.prometheus_service_active?)
  end
end

Projects::AlertManagementHelper.prepend_if_ee('EE::Projects::AlertManagementHelper')

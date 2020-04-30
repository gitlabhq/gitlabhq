# frozen_string_literal: true

module Projects::AlertManagementHelper
  def alert_management_data(current_user, project)
    {
      'project-path' => project.full_path,
      'enable-alert-management-path' => project_settings_operations_path(project),
      'empty-alert-svg-path' => image_path('illustrations/alert-management-empty-state.svg'),
      'user-can-enable-alert-management' => 'false',
      'alert-management-enabled' => Feature.enabled?(:alert_management_minimal, project).to_s
    }
  end
end

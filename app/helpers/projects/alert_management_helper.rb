# frozen_string_literal: true

module Projects::AlertManagementHelper
  def alert_management_data(project)
    {
      'index-path' => project_alert_management_index_path(project,
                                                        format: :json),
      'enable-alert-management-path' => project_settings_operations_path(project),
      'empty-alert-svg-path' => image_path('illustrations/alert-management-empty-state.svg')
    }
  end
end

# frozen_string_literal: true

module Projects::ErrorTrackingHelper
  def error_tracking_data(project)
    error_tracking_enabled = !!project.error_tracking_setting&.enabled?

    {
      'index-path' => project_error_tracking_index_path(project,
                                                        format: :json),
      'enable-error-tracking-link' => project_settings_operations_path(project),
      'error-tracking-enabled' => error_tracking_enabled.to_s,
      'illustration-path' => image_path('illustrations/cluster_popover.svg')
    }
  end
end

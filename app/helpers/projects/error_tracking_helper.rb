# frozen_string_literal: true

module Projects::ErrorTrackingHelper
  def error_tracking_data(current_user, project)
    error_tracking_enabled = !!project.error_tracking_setting&.enabled?

    {
      'index-path' => project_error_tracking_index_path(project, format: :json),
      'user-can-enable-error-tracking' => can?(current_user, :admin_operations, project).to_s,
      'enable-error-tracking-link' => project_settings_operations_path(project),
      'error-tracking-enabled' => error_tracking_enabled.to_s,
      'integrated-error-tracking-enabled' => integrated_tracking_enabled?(project).to_s,
      'project-path' => project.full_path,
      'list-path' => project_error_tracking_index_path(project),
      'illustration-path' => image_path('illustrations/empty-state/empty-radar-md.svg'),
      'show-integrated-tracking-disabled-alert' => show_integrated_tracking_disabled_alert?(project).to_s
    }
  end

  def error_details_data(project, issue_id)
    opts = [project, issue_id, { format: :json }]

    {
      'issue-id' => issue_id,
      'project-path' => project.full_path,
      'issue-update-path' => update_project_error_tracking_index_path(*opts),
      'project-issues-path' => project_issues_path(project),
      'issue-stack-trace-path' => stack_trace_project_error_tracking_index_path(*opts),
      'integrated-error-tracking-enabled' => integrated_tracking_enabled?(project).to_s
    }
  end

  private

  # Should show the alert if the FF was turned off after the integrated client has been configured.
  def show_integrated_tracking_disabled_alert?(project)
    return false if ::Feature.enabled?(:integrated_error_tracking, project)

    integrated_client_enabled?(project)
  end

  def integrated_tracking_enabled?(project)
    ::Feature.enabled?(:integrated_error_tracking, project) && integrated_client_enabled?(project)
  end

  def integrated_client_enabled?(project)
    setting ||= project.error_tracking_setting ||
      project.build_error_tracking_setting

    setting.integrated_enabled?
  end
end

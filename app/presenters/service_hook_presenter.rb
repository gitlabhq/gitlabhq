# frozen_string_literal: true

class ServiceHookPresenter < Gitlab::View::Presenter::Delegated
  presents ::ServiceHook

  def logs_details_path(log)
    project_settings_integration_hook_log_path(integration.project, integration, log)
  end

  def logs_retry_path(log)
    retry_project_settings_integration_hook_log_path(integration.project, integration, log)
  end
end

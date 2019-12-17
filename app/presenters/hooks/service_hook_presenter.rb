# frozen_string_literal: true

class ServiceHookPresenter < Gitlab::View::Presenter::Delegated
  presents :service_hook

  def logs_details_path(log)
    project_service_hook_log_path(service.project, service, log)
  end

  def logs_retry_path(log)
    retry_project_service_hook_log_path(service.project, service, log)
  end
end

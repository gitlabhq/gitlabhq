# frozen_string_literal: true

class ProjectHookPresenter < Gitlab::View::Presenter::Delegated
  presents ::ProjectHook

  def logs_details_path(log)
    project_hook_hook_log_path(project, self, log)
  end

  def logs_retry_path(log)
    retry_project_hook_hook_log_path(project, self, log)
  end
end

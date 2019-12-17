# frozen_string_literal: true

class WebHookLogPresenter < Gitlab::View::Presenter::Delegated
  presents :web_hook_log

  def details_path
    web_hook.present.logs_details_path(self)
  end

  def retry_path
    web_hook.present.logs_retry_path(self)
  end
end

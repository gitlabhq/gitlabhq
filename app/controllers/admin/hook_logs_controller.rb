# frozen_string_literal: true

module Admin
  class HookLogsController < Admin::ApplicationController
    include WebHooks::HookLogActions

    private

    def hook
      @hook ||= SystemHook.find(params[:hook_id])
    end

    def after_retry_redirect_path
      edit_admin_hook_path(hook)
    end
  end
end

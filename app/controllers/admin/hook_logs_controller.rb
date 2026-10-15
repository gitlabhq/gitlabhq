# frozen_string_literal: true

module Admin
  class HookLogsController < Admin::ApplicationController
    include WebHooks::HookLogActions

    private

    def hook
      @hook ||= relation.find(params.permit(:hook_id)[:hook_id])
    end

    def relation
      admin_current_organization.system_hooks
    end

    def after_retry_redirect_path
      edit_admin_hook_path(hook)
    end
  end
end

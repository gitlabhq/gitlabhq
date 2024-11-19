# frozen_string_literal: true

module WebHooks
  module HookLogActions
    extend ActiveSupport::Concern
    include HookExecutionNotice

    included do
      before_action :hook, only: [:show, :retry]
      before_action :hook_log, only: [:show, :retry]

      respond_to :html

      feature_category :webhooks
      urgency :low, [:retry]
    end

    def show
      hide_search_settings
    end

    def retry
      result = execute_hook
      if result.success?
        redirect_to after_retry_redirect_path
      else
        flash[:warning] = result.message
        redirect_back(fallback_location: after_retry_redirect_path)
      end
    end

    private

    def hook_log
      @hook_log ||= hook.web_hook_logs.find(params[:id])
    end

    def execute_hook
      result = WebHooks::Events::ResendService.new(hook_log, current_user: current_user).execute
      set_hook_execution_notice(result)
      result
    end

    def hide_search_settings
      @hide_search_settings ||= true
    end
  end
end

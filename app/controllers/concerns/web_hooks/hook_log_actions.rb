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
      if hook_log.url_current?
        execute_hook
        redirect_to after_retry_redirect_path
      else
        flash[:warning] = _('The hook URL has changed, and this log entry cannot be retried')
        redirect_back(fallback_location: after_retry_redirect_path)
      end
    end

    private

    # rubocop:disable Gitlab/ModuleWithInstanceVariables
    def hook_log
      @hook_log ||= hook.web_hook_logs.find(params[:id])
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables

    def execute_hook
      result = hook.execute(hook_log.request_data, hook_log.trigger, idempotency_key: hook_log.idempotency_key)
      set_hook_execution_notice(result)
    end

    def hide_search_settings
      @hide_search_settings ||= true
    end
  end
end

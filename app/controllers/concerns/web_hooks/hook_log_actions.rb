# frozen_string_literal: true

module WebHooks
  module HookLogActions
    extend ActiveSupport::Concern
    include HookExecutionNotice

    included do
      before_action :hook, only: [:show, :retry]
      before_action :hook_log, only: [:show, :retry]

      respond_to :html

      feature_category :integrations
      urgency :low, [:retry]
    end

    def show
      hide_search_settings
    end

    def retry
      execute_hook
      redirect_to after_retry_redirect_path
    end

    private

    # rubocop:disable Gitlab/ModuleWithInstanceVariables
    def hook_log
      @hook_log ||= hook.web_hook_logs.find(params[:id])
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables

    def execute_hook
      result = hook.execute(hook_log.request_data, hook_log.trigger)
      set_hook_execution_notice(result)
    end

    def hide_search_settings
      @hide_search_settings ||= true
    end
  end
end

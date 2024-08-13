# frozen_string_literal: true

module WebHooks
  class WebHookLogsFinder
    attr_accessor :hooks, :params, :current_user

    def initialize(hook, current_user, params = {})
      @hook = hook
      @current_user = current_user
      @params = params
    end

    def execute
      return WebHookLog.none unless authorized?(@hook)

      logs = @hook.web_hook_logs
      logs = by_status_code(logs)
      logs.recent(WebHookLog::MAX_RECENT_DAYS)
    end

    private

    def authorized?(hook)
      Ability.allowed?(current_user, :read_web_hook, hook)
    end

    def by_status_code(logs)
      return logs unless params[:status]

      filters = params[:status].flat_map { |status| string_filter_to_code(status) }

      filters.map { |code| logs.by_status_code(code) }.reduce(:or)
    end

    def string_filter_to_code(status_string)
      case status_string
      when 'successful'
        (200..299)
      when 'client_failure'
        (400..499)
      when 'server_failure'
        [(500..599), WebHookService::InternalErrorResponse::ERROR_MESSAGE]
      else
        status_string
      end
    end
  end
end

WebHooks::WebHookLogsFinder.prepend_mod

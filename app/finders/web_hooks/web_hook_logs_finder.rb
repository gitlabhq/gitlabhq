# frozen_string_literal: true

module WebHooks
  class WebHookLogsFinder
    attr_accessor :hook, :params, :current_user

    def initialize(hook, current_user, params = {})
      @hook = hook
      @current_user = current_user
      @params = params
    end

    def execute
      return WebHookLog.none unless authorized?

      logs = hook.web_hook_logs
      logs = by_status_code(logs)
      logs = by_created_at(logs)
      by_id(logs)
    end

    private

    def authorized?
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

    def by_created_at(logs)
      return logs.created_between(params[:start_time], params[:end_time]) if params[:start_time] || params[:end_time]

      logs.recent(::WebHookLog::MAX_RECENT_DAYS)
    end

    def by_id(logs)
      return logs unless params[:id]

      logs.id_in(params[:id])
    end
  end
end

WebHooks::WebHookLogsFinder.prepend_mod

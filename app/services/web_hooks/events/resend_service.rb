# frozen_string_literal: true

module WebHooks
  module Events
    class ResendService
      def initialize(web_hook_log, current_user:)
        @web_hook_log = web_hook_log
        @current_user = current_user
      end

      def execute
        return unauthorized_response unless authorized?
        return url_changed_response unless web_hook_log.url_current?

        web_hook_log.web_hook.execute(web_hook_log.request_data, web_hook_log.trigger,
          idempotency_key: web_hook_log.idempotency_key)
      end

      private

      def authorized?
        case web_hook_log.web_hook.type
        when 'ServiceHook'
          current_user.can?(:admin_integrations, web_hook_log.web_hook.integration)
        else
          current_user.can?(:admin_web_hook, web_hook_log.web_hook)
        end
      end

      def unauthorized_response
        ServiceResponse.error(message: s_('WebHooks|The current user is not authorized to resend a hook event'))
      end

      def url_changed_response
        ServiceResponse.error(
          message: _('The hook URL has changed, and this log entry cannot be retried')
        )
      end

      attr_reader :web_hook_log, :current_user
    end
  end
end

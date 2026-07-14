# frozen_string_literal: true

module Gitlab
  module WebHooks
    class Logger < ::Gitlab::JsonLogger
      STALE_LOG_ACCESS_EVENT = 'web_hook_log_stale_access'
      STALE_LOG_ACCESS_MESSAGE = 'Web hook log viewed or retried outside retention window'

      def self.file_name_noext
        'web_hooks'
      end

      # Logged when a hook's `show` or `retry` action is invoked on a WebHookLog
      # older than WebHookLog::MAX_RECENT_DAYS. Such logs are no longer visible in
      # the log list/index (see WebHookLog.recent), so this indicates the caller is
      # acting on an id obtained outside of the current list, e.g. a bookmarked
      # link, browser history, or a script that stored ids earlier.
      def self.log_stale_access(hook:, web_hook_log:, action:, interface:, user:)
        build.info(
          class: name,
          event: STALE_LOG_ACCESS_EVENT,
          message: STALE_LOG_ACCESS_MESSAGE,
          hook_id: hook.id,
          web_hook_log_id: web_hook_log.id,
          web_hook_log_created_at: web_hook_log.created_at,
          action: action,
          interface: interface,
          user_id: user&.id,
          Labkit::Fields::GL_ORGANIZATION_ID => hook.parent&.organization_id
        )
      end
    end
  end
end

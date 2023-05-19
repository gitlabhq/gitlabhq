# frozen_string_literal: true

module Gitlab
  module Email
    module Hook
      class SilentModeInterceptor
        def self.delivering_email(message)
          if ::Gitlab::SilentMode.enabled?
            message.perform_deliveries = false

            ::Gitlab::SilentMode.log_info(
              message: "SilentModeInterceptor prevented sending mail",
              mail_subject: message.subject
            )
          else
            ::Gitlab::SilentMode.log_debug(
              message: "SilentModeInterceptor did nothing",
              mail_subject: message.subject
            )
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Email
    module Hook
      class SilentModeInterceptor
        def self.delivering_email(message)
          if Gitlab::CurrentSettings.silent_mode_enabled?
            message.perform_deliveries = false

            Gitlab::AppJsonLogger.info(
              message: "SilentModeInterceptor prevented sending mail",
              mail_subject: message.subject,
              silent_mode_enabled: true
            )
          else
            Gitlab::AppJsonLogger.debug(
              message: "SilentModeInterceptor did nothing",
              mail_subject: message.subject,
              silent_mode_enabled: false
            )
          end
        end
      end
    end
  end
end

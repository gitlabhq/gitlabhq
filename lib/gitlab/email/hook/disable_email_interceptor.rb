# frozen_string_literal: true

module Gitlab
  module Email
    module Hook
      class DisableEmailInterceptor
        def self.delivering_email(message)
          message.perform_deliveries = false

          Gitlab::AppLogger.info "Emails disabled! Interceptor prevented sending mail #{message.subject}"
        end
      end
    end
  end
end

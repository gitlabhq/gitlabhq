# frozen_string_literal: true

module Gitlab
  module Email
    module ServiceDesk
      # Doesn't include Gitlab::Email::Common because a custom email doesn't
      # support all features and methods of ingestable email addresses like
      # incoming_email and service_desk_email.
      module CustomEmail
        class << self
          def reply_address(issue, reply_key)
            return if reply_key.nil?

            custom_email = issue&.project&.service_desk_setting&.custom_email
            return if custom_email.nil?

            # Reply keys for custom email addresses always go before the @.
            # We don't have a placeholder.
            custom_email.sub('@', "+#{reply_key}@")
          end
        end
      end
    end
  end
end

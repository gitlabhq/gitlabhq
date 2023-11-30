# frozen_string_literal: true

module Gitlab
  module Email
    module ServiceDesk
      # Doesn't include Gitlab::Email::Common because a custom email doesn't
      # support all features and methods of ingestable email addresses like
      # incoming_email and service_desk_email.
      module CustomEmail
        REPLY_ADDRESS_KEY_REGEXP = /\+([0-9a-f]{32})@/
        EMAIL_REGEXP = /\A[\w\-._]+@[\w\-.]+\.{1}[a-zA-Z]{2,}\z/

        class << self
          def reply_address(issue, reply_key)
            return if reply_key.nil?

            custom_email = issue&.project&.service_desk_setting&.custom_email
            return if custom_email.nil?

            # Reply keys for custom email addresses always go before the @.
            # We don't have a placeholder.
            custom_email.sub('@', "+#{reply_key}@")
          end

          def key_from_reply_address(email)
            match_data = REPLY_ADDRESS_KEY_REGEXP.match(email)
            return unless match_data

            key = match_data[1]

            settings = find_service_desk_setting_from_reply_address(email, key)
            # We intentionally don't check whether custom email is enabled
            # so we don't lose emails that are addressed to a disabled custom email address
            return unless settings

            key
          end

          private

          def find_service_desk_setting_from_reply_address(email, key)
            potential_custom_email = email.sub("+#{key}", '')
            return unless EMAIL_REGEXP.match?(potential_custom_email)

            ServiceDeskSetting.find_by_custom_email(potential_custom_email)
          end
        end
      end
    end
  end
end

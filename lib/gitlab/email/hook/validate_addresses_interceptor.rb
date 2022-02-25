# frozen_string_literal: true

module Gitlab
  module Email
    module Hook
      # Check for unsafe characters in the envelope-from and -to addresses.
      # These are passed directly as arguments to sendmail and are liable to shell injection attacks:
      # https://github.com/mikel/mail/blob/2.7.1/lib/mail/network/delivery_methods/sendmail.rb#L53-L58
      class ValidateAddressesInterceptor
        UNSAFE_CHARACTERS = /(\\|[^[:print:]])/.freeze

        def self.delivering_email(message)
          addresses = Array(message.smtp_envelope_from) + Array(message.smtp_envelope_to)

          addresses.each do |address|
            next unless address.match?(UNSAFE_CHARACTERS)

            Gitlab::AuthLogger.info(
              message: 'Skipping email with unsafe characters in address',
              address: address,
              subject: message.subject
            )

            message.perform_deliveries = false

            break
          end
        end
      end
    end
  end
end

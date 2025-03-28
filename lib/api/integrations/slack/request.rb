# frozen_string_literal: true

module API
  class Integrations
    module Slack
      module Request
        VERIFICATION_VERSION = 'v0'
        VERIFICATION_TIMESTAMP_HEADER = 'X-Slack-Request-Timestamp'
        VERIFICATION_SIGNATURE_HEADER = 'X-Slack-Signature'
        VERIFICATION_DELIMITER = ':'
        VERIFICATION_HMAC_ALGORITHM = 'sha256'
        VERIFICATION_TIMESTAMP_EXPIRY = 1.minute.to_i

        # Verify the request by comparing the given request signature in the header
        # with a signature value that we compute according to the steps in:
        # https://api.slack.com/authentication/verifying-requests-from-slack.
        def self.verify!(request)
          return false unless Gitlab::CurrentSettings.slack_app_signing_secret

          timestamp, signature = request.headers.values_at(
            VERIFICATION_TIMESTAMP_HEADER,
            VERIFICATION_SIGNATURE_HEADER
          )

          return false if timestamp.nil? || signature.nil?
          return false if Time.current.to_i - timestamp.to_i >= VERIFICATION_TIMESTAMP_EXPIRY

          request.body.rewind

          basestring = [
            VERIFICATION_VERSION,
            timestamp,
            request.body.read
          ].join(VERIFICATION_DELIMITER)

          hmac_digest = OpenSSL::HMAC.hexdigest(
            VERIFICATION_HMAC_ALGORITHM,
            Gitlab::CurrentSettings.slack_app_signing_secret,
            basestring
          )

          # Signature will look like: 'v0=a2114d57b48eac39b9ad189dd8316235a7b4a8d21a10bd27519666489c69b503'
          ActiveSupport::SecurityUtils.secure_compare(
            signature,
            "#{VERIFICATION_VERSION}=#{hmac_digest}"
          )
        end
      end
    end
  end
end

API::Integrations::Slack::Request.prepend_mod

# frozen_string_literal: true

require 'openssl'

module Gitlab
  module Ci
    module Ansi2json
      class SignedState < ::Gitlab::Ci::Ansi2json::State
        include Gitlab::Utils::StrongMemoize

        SIGNATURE_KEY_SALT = 'gitlab-ci-ansi2json-state'
        SEPARATOR = '--'

        def encode
          encoded = super

          encoded + SEPARATOR + sign(encoded)
        end

        private

        def sign(message)
          ::OpenSSL::HMAC.hexdigest(
            signature_digest,
            signature_key,
            message
          )
        end

        def verify(signed_message)
          signature_length = signature_digest.digest_length * 2 # a byte is exactly two hexadecimals
          message_length = signed_message.length - SEPARATOR.length - signature_length
          return if message_length <= 0

          signature = signed_message.last(signature_length)
          message = signed_message.first(message_length)
          return unless valid_signature?(message, signature)

          message
        end

        def valid_signature?(message, signature)
          expected_signature = sign(message)
          expected_signature.bytesize == signature.bytesize &&
            ::OpenSSL.fixed_length_secure_compare(signature, expected_signature)
        end

        def decode_state(data)
          return if data.blank?

          encoded_state = verify(data)
          if encoded_state.blank?
            ::Gitlab::AppLogger.warn(message: "#{self.class}: signature missing or invalid", invalid_state: data)
            return
          end

          decoded_state = Base64.urlsafe_decode64(encoded_state)
          return unless decoded_state.present?

          ::Gitlab::Json.parse(decoded_state)
        end

        def signature_digest
          ::OpenSSL::Digest.new('SHA256')
        end

        def signature_key
          ::Gitlab::Application.key_generator.generate_key(SIGNATURE_KEY_SALT, signature_digest.block_length)
        end
        strong_memoize_attr :signature_key
      end
    end
  end
end

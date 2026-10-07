# frozen_string_literal: true

module Authn
  module TokenField
    class EncryptionHelper
      DYNAMIC_NONCE_IDENTIFIER = "|"
      NONCE_SIZE = 12

      def self.decrypt_token(token)
        return unless token

        # The pattern of the token is "#{DYNAMIC_NONCE_IDENTIFIER}#{token}#{iv_of_12_characters}"
        if token.start_with?(DYNAMIC_NONCE_IDENTIFIER) && token.size > NONCE_SIZE + DYNAMIC_NONCE_IDENTIFIER.size
          token_to_decrypt = token[1...-NONCE_SIZE]
          iv = token[-NONCE_SIZE..]

          Gitlab::CryptoHelper.aes256_gcm_decrypt(token_to_decrypt, nonce: iv)
        else
          Gitlab::CryptoHelper.aes256_gcm_decrypt(token)
        end
      end

      def self.encrypt_token(plaintext_token)
        iv = nonce_for(plaintext_token)
        token = Gitlab::CryptoHelper.aes256_gcm_encrypt(plaintext_token, nonce: iv)
        "#{DYNAMIC_NONCE_IDENTIFIER}#{token}#{iv}"
      end

      # Every value `encrypt_token` may have stored for this token, current key first
      def self.encrypt_token_candidates(plaintext_token)
        iv = nonce_for(plaintext_token)

        Gitlab::CryptoHelper.aes256_gcm_encrypt_candidates(plaintext_token, nonce: iv).map do |token|
          "#{DYNAMIC_NONCE_IDENTIFIER}#{token}#{iv}"
        end
      end

      def self.nonce_for(plaintext_token)
        ::Digest::SHA256.hexdigest(plaintext_token).bytes.take(NONCE_SIZE).pack('c*') # rubocop:disable CodeReuse/ActiveRecord: -- This is Array#take.
      end
      private_class_method :nonce_for
    end
  end
end

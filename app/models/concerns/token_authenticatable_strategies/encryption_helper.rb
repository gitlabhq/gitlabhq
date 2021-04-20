# frozen_string_literal: true

module TokenAuthenticatableStrategies
  class EncryptionHelper
    DYNAMIC_NONCE_IDENTIFIER = "|"
    NONCE_SIZE = 12

    def self.encrypt_token(plaintext_token)
      Gitlab::CryptoHelper.aes256_gcm_encrypt(plaintext_token)
    end

    def self.decrypt_token(token)
      return unless token

      # The pattern of the token is "#{DYNAMIC_NONCE_IDENTIFIER}#{token}#{iv_of_12_characters}"
      if token.start_with?(DYNAMIC_NONCE_IDENTIFIER) && token.size > NONCE_SIZE + DYNAMIC_NONCE_IDENTIFIER.size
        token_to_decrypt = token[1...-NONCE_SIZE]
        iv = token[-NONCE_SIZE..-1]

        Gitlab::CryptoHelper.aes256_gcm_decrypt(token_to_decrypt, nonce: iv)
      else
        Gitlab::CryptoHelper.aes256_gcm_decrypt(token)
      end
    end
  end
end

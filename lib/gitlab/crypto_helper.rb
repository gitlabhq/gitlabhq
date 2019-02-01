# frozen_string_literal: true

module Gitlab
  module CryptoHelper
    extend self

    AES256_GCM_OPTIONS = {
      algorithm: 'aes-256-gcm',
      key: Settings.attr_encrypted_db_key_base_32,
      iv: Settings.attr_encrypted_db_key_base_12
    }.freeze

    def sha256(value)
      salt = Settings.attr_encrypted_db_key_base_truncated
      ::Digest::SHA256.base64digest("#{value}#{salt}")
    end

    def aes256_gcm_encrypt(value)
      encrypted_token = Encryptor.encrypt(AES256_GCM_OPTIONS.merge(value: value))
      Base64.strict_encode64(encrypted_token)
    end

    def aes256_gcm_decrypt(value)
      return unless value

      encrypted_token = Base64.decode64(value)
      Encryptor.decrypt(AES256_GCM_OPTIONS.merge(value: encrypted_token))
    end
  end
end

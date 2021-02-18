# frozen_string_literal: true

module Gitlab
  module CryptoHelper
    extend self

    AES256_GCM_OPTIONS = {
      algorithm: 'aes-256-gcm',
      key: Settings.attr_encrypted_db_key_base_32
    }.freeze

    AES256_GCM_IV_STATIC = Settings.attr_encrypted_db_key_base_12

    def sha256(value)
      salt = Settings.attr_encrypted_db_key_base_truncated
      ::Digest::SHA256.base64digest("#{value}#{salt}")
    end

    def aes256_gcm_encrypt(value, nonce: nil)
      aes256_gcm_encrypt_using_static_nonce(value)
    end

    def aes256_gcm_decrypt(value)
      return unless value

      nonce = Feature.enabled?(:dynamic_nonce_creation) ? dynamic_nonce(value) : AES256_GCM_IV_STATIC
      encrypted_token = Base64.decode64(value)
      decrypted_token = Encryptor.decrypt(AES256_GCM_OPTIONS.merge(value: encrypted_token, iv: nonce))
      decrypted_token
    end

    def dynamic_nonce(value)
      TokenWithIv.find_nonce_by_hashed_token(value) || AES256_GCM_IV_STATIC
    end

    def aes256_gcm_encrypt_using_static_nonce(value)
      create_encrypted_token(value, AES256_GCM_IV_STATIC)
    end

    def read_only?
      Gitlab::Database.read_only?
    end

    def create_encrypted_token(value, iv)
      encrypted_token = Encryptor.encrypt(AES256_GCM_OPTIONS.merge(value: value, iv: iv))
      Base64.strict_encode64(encrypted_token)
    end
  end
end

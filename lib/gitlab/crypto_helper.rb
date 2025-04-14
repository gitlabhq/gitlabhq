# frozen_string_literal: true

module Gitlab
  module CryptoHelper
    extend self

    AES256_GCM_OPTIONS = {
      algorithm: 'aes-256-gcm'
    }.freeze

    def sha256(value)
      salt = Gitlab::Encryption::KeyProvider[:db_key_base_truncated].encryption_key.secret
      ::Digest::SHA256.base64digest("#{value}#{salt}")
    end

    def encryption_key
      @encryption_key ||= Gitlab::Encryption::KeyProvider[:db_key_base_32].encryption_key
    end

    def aes256_gcm_encrypt(value, nonce: nil)
      encrypted_token = Encryptor.encrypt(
        AES256_GCM_OPTIONS.merge(
          value: value,
          iv: nonce || Gitlab::Utils.ensure_utf8_size(encryption_key.secret, bytes: 12.bytes),
          key: encryption_key.secret
        )
      )
      Base64.strict_encode64(encrypted_token)
    end

    def aes256_gcm_decrypt(value, nonce: nil)
      return unless value

      encrypted_token = Base64.decode64(value)
      keys = Gitlab::Encryption::KeyProvider[:db_key_base_32].decryption_keys

      # Try to decrypt with all keys, from oldest to newest
      keys.each_with_index do |key, index|
        return Encryptor.decrypt( # rubocop:disable Cop/AvoidReturnFromBlocks -- next doesn't work the same here
          AES256_GCM_OPTIONS.merge(
            value: encrypted_token,
            key: key.secret,
            iv: nonce || Gitlab::Utils.ensure_utf8_size(key.secret, bytes: 12.bytes)
          )
        )
      rescue OpenSSL::Cipher::CipherError
        raise if index == keys.length - 1
      end
    end
  end
end

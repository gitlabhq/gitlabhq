# frozen_string_literal: true

module Gitlab
  module EncryptedAttribute
    extend ActiveSupport::Concern

    private

    def db_key_base
      dynamic_encryption_key(:db_key_base)
    end

    def db_key_base_32
      dynamic_encryption_key(:db_key_base_32)
    end

    def db_key_base_truncated
      dynamic_encryption_key(:db_key_base_truncated)
    end

    def dynamic_encryption_key(key_type)
      dynamic_encryption_key_for_operation(key_type)
    end

    def dynamic_encryption_key_for_operation(key_type)
      # We always use the encryption key, which is the only key defined since
      # we don't support multiple keys in attr_encrypted but only with
      # Active Record Encryption.
      Gitlab::Encryption::KeyProvider[key_type].encryption_key.secret
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module EncryptedAttribute
    extend ActiveSupport::Concern

    private

    def db_key_base(attribute)
      dynamic_encryption_key(:db_key_base, attribute)
    end

    def db_key_base_32(attribute)
      dynamic_encryption_key(:db_key_base_32, attribute)
    end

    def db_key_base_truncated(attribute)
      dynamic_encryption_key(:db_key_base_truncated, attribute)
    end

    def dynamic_encryption_key(key_type, attribute)
      dynamic_encryption_key_for_operation(key_type, attr_encrypted_attributes[attribute][:operation])
    end

    def dynamic_encryption_key_for_operation(key_type, operation)
      if operation == :encrypting
        Gitlab::Encryption::KeyProvider[key_type].encryption_key.secret
      else
        Gitlab::Encryption::KeyProvider[key_type].decryption_keys.map(&:secret)
      end
    end
  end
end

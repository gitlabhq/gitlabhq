# frozen_string_literal: true

module Gitlab
  module EncryptedAttribute
    extend ActiveSupport::Concern

    class_methods do
      def migrate_to_encrypts(attribute, *options)
        tmp_column_name = :"tmp_#{attribute}"

        attr_encrypted attribute, *options # rubocop:disable Gitlab/Rails/AttrEncrypted -- This is specifically to migrate from attr_encrypted
        encrypts tmp_column_name

        attr_encrypted_prefixed_attribute_name = :"attr_encrypted_#{attribute}"

        alias_method attr_encrypted_prefixed_attribute_name, attribute
        alias_method :"#{attr_encrypted_prefixed_attribute_name}=", :"#{attribute}="

        # rubocop:disable GitlabSecurity/PublicSend -- We're calling methods dynamically but this is only temporary until all attr_encrypted attributes are migrated
        define_method(attribute) do
          public_send(tmp_column_name).presence || public_send(attr_encrypted_prefixed_attribute_name)
        end

        alias_method :"#{attribute}_attr_encrypted=", :"#{attribute}="

        define_method(:"#{attribute}=") do |value|
          public_send(:"#{attribute}_attr_encrypted=", value)
          public_send(:"#{tmp_column_name}=", value)
        end
        # rubocop:enable GitlabSecurity/PublicSend
      end
    end

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

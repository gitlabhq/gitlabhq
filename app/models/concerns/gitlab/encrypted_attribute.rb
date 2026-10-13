# frozen_string_literal: true

module Gitlab
  module EncryptedAttribute
    extend ActiveSupport::Concern

    AmbiguousDecryptionError = Class.new(StandardError)

    DB_KEY_BASE_KEY_TYPES = %i[db_key_base db_key_base_32 db_key_base_truncated].freeze

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

    # Overrides AttrEncrypted::InstanceMethods#attr_encrypted_decrypt to decrypt
    # with every `db_key_base` key. `overrides` replaces evaluated options, e.g.
    # the IV when decrypting a previous value.
    def attr_encrypted_decrypt(attribute, encrypted_value, **overrides)
      unless Feature.enabled?(:attr_encrypted_multi_key_decrypt, Feature.current_request)
        return super(attribute, encrypted_value) if overrides.empty?

        key = dynamic_encryption_key(attr_encrypted_encrypted_attributes[attribute.to_sym][:key])
        return self.class.attr_encrypted_decrypt(attribute, encrypted_value, { key: key, **overrides })
      end

      attr_encrypted_decrypt_with_key_used(attribute, encrypted_value, **overrides).first
    end

    # :current when the stored value decrypts with the current `db_key_base`
    # key, :previous when it needs an older key, or nil when the value is empty
    # or the `:if`/`:unless` options skip decryption.
    def attr_encrypted_encrypted_with(attribute)
      encrypted_attribute_name = attr_encrypted_encrypted_attributes[attribute.to_sym][:attribute]

      attr_encrypted_decrypt_with_key_used(attribute, read_attribute(encrypted_attribute_name)).last
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
      # Always the current key: decryption tries every key in attr_encrypted_decrypt.
      Gitlab::Encryption::KeyProvider[key_type].encryption_key.secret
    end

    def attr_encrypted_decrypt_with_key_used(attribute, encrypted_value, **overrides)
      attribute_options = attr_encrypted_encrypted_attributes[attribute.to_sym]
      attribute_options[:operation] = :decrypting
      attribute_options[:value_present] = self.class.not_empty?(encrypted_value)
      options = evaluated_attr_encrypted_options_for(attribute).merge(overrides)
      keys = attr_encrypted_decryption_keys(attribute_options[:key])

      unless keys && options[:if] && !options[:unless] && attribute_options[:value_present]
        return [self.class.attr_encrypted_decrypt(attribute, encrypted_value, options), nil]
      end

      attr_encrypted_decrypt_with_keys(attribute, encrypted_value, options, keys)
    end

    # GCM rejects a wrong key, so the first key that works wins. CBC accepts a
    # wrong key about 1 time in 256 and returns garbage, so every key is tried;
    # when several succeed, plausibility breaks the tie.
    def attr_encrypted_decrypt_with_keys(attribute, encrypted_value, options, keys)
      first_match_wins = keys.one? || options[:algorithm].to_s.end_with?('-gcm')
      matches = []
      error = nil

      keys.each_with_index.reverse_each do |key, index|
        value = self.class.attr_encrypted_decrypt(attribute, encrypted_value, options.merge(key: key))
        matches << [value, index == keys.size - 1 ? :current : :previous]
        break if first_match_wins
      rescue StandardError => e
        # A wrong CBC key that passes the padding check can make the load raise anything
        raise if first_match_wins && !e.is_a?(OpenSSL::Cipher::CipherError)

        error ||= e
      end

      raise error if matches.empty?

      attr_encrypted_unique_match(attribute, matches, options)
    end

    def attr_encrypted_unique_match(attribute, matches, options)
      # Identical keys (e.g. sharing their first 32 bytes) give identical values
      return matches.first if matches.map(&:first).uniq.one?

      matches = matches.select { |value, _| attr_encrypted_plausible_value?(value, options) }
      return matches.first if matches.map(&:first).uniq.one?
      raise OpenSSL::Cipher::CipherError, 'bad decrypt' if matches.empty?

      raise AmbiguousDecryptionError,
        "#{self.class.name}##{attribute} can be decrypted with more than one db_key_base key"
    end

    def attr_encrypted_decryption_keys(key_type)
      return unless DB_KEY_BASE_KEY_TYPES.include?(key_type)

      Gitlab::Encryption::KeyProvider[key_type].decryption_keys.map(&:secret)
    end

    # Marshaled values are already checked by a successful load.
    def attr_encrypted_plausible_value?(value, options)
      options[:marshal] || !value.is_a?(String) || value.valid_encoding?
    end
  end
end

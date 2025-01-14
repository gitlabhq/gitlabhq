# frozen_string_literal: true

module Authn
  module TokenField
    class Encrypted < Base
      def token_fields
        super + [encrypted_field]
      end

      def find_token_authenticatable(token, unscoped = false)
        return if token.blank?

        token_owner_record =
          if required?
            find_by_encrypted_token(token, unscoped)
          elsif optional?
            find_by_encrypted_token(token, unscoped) ||
              find_by_plaintext_token(token, unscoped)
          elsif migrating?
            find_by_plaintext_token(token, unscoped)
          end

        token_owner_record if token_owner_record && matches_prefix?(token_owner_record, token)
      end

      def ensure_token(token_owner_record)
        # TODO, tech debt, because some specs are testing migrations, but are still
        # using factory bot to create resources, it might happen that a database
        # schema does not have "#{token_name}_encrypted" field yet, however a bunch
        # of models call `ensure_#{token_name}` in `before_save`.
        #
        # In that case we are using insecure strategy, but this should only happen
        # in tests, because otherwise `encrypted_field` is going to exist.
        #
        # Another use case is when we are caching resources / columns, like we do
        # in case of ApplicationSetting.

        return super if token_owner_record.has_attribute?(encrypted_field)

        if required? # rubocop:disable Style/GuardClause -- Multiple guard clauses + guard clause with `if` modifier is messy
          raise ArgumentError, _('Using required encryption strategy when encrypted field is missing!')
        else
          insecure_strategy.ensure_token(token_owner_record)
        end
      end

      def get_token(token_owner_record)
        return insecure_strategy.get_token(token_owner_record) if migrating?

        get_encrypted_token(token_owner_record)
      end

      def set_token(token_owner_record, token)
        raise ArgumentError unless token.present?

        token_owner_record[encrypted_field] = Authn::TokenField::EncryptionHelper.encrypt_token(token)
        token_owner_record[token_field] = token if migrating?
        token_owner_record[token_field] = nil if optional?
        token
      end

      def required?
        encrypted_strategy == :required
      end

      def migrating?
        encrypted_strategy == :migrating
      end

      def optional?
        encrypted_strategy == :optional
      end

      protected

      def get_encrypted_token(token_owner_record)
        encrypted_token = token_owner_record.read_attribute(encrypted_field)
        token = Authn::TokenField::EncryptionHelper.decrypt_token(encrypted_token)
        token || (insecure_strategy.get_token(token_owner_record) if optional?)
      end

      def encrypted_strategy
        value = options[:encrypted]
        value = value.call if value.is_a?(Proc)

        unless value.in?([:required, :optional, :migrating])
          raise ArgumentError, _('encrypted: needs to be a :required, :optional or :migrating!')
        end

        value
      end

      def find_by_plaintext_token(token, unscoped)
        insecure_strategy.find_token_authenticatable(token, unscoped)
      end

      def find_by_encrypted_token(token, unscoped)
        encrypted_value = Authn::TokenField::EncryptionHelper.encrypt_token(token)
        token_encrypted_with_static_iv = Gitlab::CryptoHelper.aes256_gcm_encrypt(token)
        relation(unscoped).find_by(encrypted_field => [encrypted_value, token_encrypted_with_static_iv]) # rubocop:disable CodeReuse/ActiveRecord: -- This is meant to be used in AR models.
      end

      def insecure_strategy
        @insecure_strategy ||= Authn::TokenField::Insecure
          .new(klass, token_field, options)
      end

      def matches_prefix?(token_owner_record, token)
        !options[:require_prefix_for_validation] || token.start_with?(prefix_for(token_owner_record))
      end

      def token_set?(token_owner_record)
        token = get_encrypted_token(token_owner_record)
        token ||= insecure_strategy.get_token(token_owner_record) unless required?

        token.present? && matches_prefix?(token_owner_record, token)
      end

      def encrypted_field
        @encrypted_field ||= "#{@token_field}_encrypted"
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Encryption
    class KeyProvider
      include Singleton

      KeyProviderBuilder = Struct.new(:builder_class, :secrets, keyword_init: true) do
        def build
          builder_class.new(secrets.call)
        end

        def builder_class
          @builder_class ||= self[:builder_class] || NonDerivedKeyProvider
        end
      end

      KEY_PROVIDERS = {
        db_key_base: KeyProviderBuilder.new(
          secrets: -> { Settings.db_key_base_keys }
        ),
        db_key_base_32: KeyProviderBuilder.new(
          secrets: -> { Settings.db_key_base_keys_32_bytes }
        ),
        db_key_base_truncated: KeyProviderBuilder.new(
          secrets: -> { Settings.db_key_base_keys_truncated }
        ),
        active_record_encryption_primary_key: KeyProviderBuilder.new(
          builder_class: ActiveRecord::Encryption::DerivedSecretKeyProvider,
          secrets: -> { ActiveRecord::Encryption.config.primary_key }
        ),
        active_record_encryption_deterministic_key: KeyProviderBuilder.new(
          builder_class: ActiveRecord::Encryption::DerivedSecretKeyProvider,
          secrets: -> { ActiveRecord::Encryption.config.deterministic_key }
        )
      }.freeze

      def self.[](key_type)
        instance.key_provider_for(key_type)
      end

      def key_provider_for(key_type)
        return providers[key_type] if providers.key?(key_type)

        raise ArgumentError, "Unsupported key type: #{key_type}" unless KEY_PROVIDERS.key?(key_type)

        providers[key_type] = KeyProviderWrapper.new(KEY_PROVIDERS[key_type].build)
      end

      private

      def providers
        @providers ||= {}
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Encryption
    # Derives per-file Lockbox keys from `db_key_base`: the current key encrypts,
    # and older keys are Lockbox previous versions so existing files still decrypt.
    module DbKeyBaseLockboxKeys
      private

      def db_key_base_lockbox_key(context)
        derive_db_key_base_lockbox_key(db_key_base_key_provider.encryption_key.secret, context)
      end

      # Newest first, like the decryption order of attr_encrypted attributes
      def db_key_base_lockbox_previous_versions(context)
        current_secret = db_key_base_key_provider.encryption_key.secret

        db_key_base_key_provider.decryption_keys.map(&:secret).reverse.filter_map do |secret|
          next if secret == current_secret

          { key: derive_db_key_base_lockbox_key(secret, context) }
        end
      end

      def derive_db_key_base_lockbox_key(secret, context)
        OpenSSL::HMAC.digest('SHA256', secret, context)
      end

      def db_key_base_key_provider
        Gitlab::Encryption::KeyProvider[:db_key_base]
      end
    end
  end
end

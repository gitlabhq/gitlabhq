# frozen_string_literal: true

module Gitlab
  module Encryption
    # Custom key provider to handle cloud connector keys encrypted with SHA1 (pre-Rails 7.1)
    # This provides backward compatibility for EnvelopeEncryptionKeyProvider which isn't handled
    # by the default support_sha1_for_non_deterministic_encryption setting.
    class Sha1EnvelopeEncryptionKeyProvider < ActiveRecord::Encryption::EnvelopeEncryptionKeyProvider
      private

      def primary_key_provider
        @primary_key_provider ||= begin
          # rubocop:disable Fips/SHA1 -- Intentionally using SHA1 for backward compatibility with existing encrypted data
          sha1_key_generator = ActiveRecord::Encryption::KeyGenerator.new(hash_digest_class: OpenSSL::Digest::SHA1)
          # rubocop:enable Fips/SHA1

          ActiveRecord::Encryption::DerivedSecretKeyProvider.new(
            ActiveRecord::Encryption.config.primary_key,
            key_generator: sha1_key_generator
          )
        end
      end
    end
  end
end

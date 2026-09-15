# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MigrateLegacyOtpSecrets < BatchedMigrationJob
      operation_name :set_otp_secret
      feature_category :system_access

      class User < ::ApplicationRecord
        self.table_name = 'users'

        encrypts :otp_secret

        # Copied from the former ::User#legacy_otp_secret, removed in 19.2 by
        # https://gitlab.com/gitlab-org/gitlab/-/commit/8309d4738a3ccf94d3ea1ca8e1f6c86563aca15a.
        # Migrations must not depend on application code (see doc/development/migration_style_guide.md).
        def legacy_otp_secret
          return unless self[:encrypted_otp_secret]

          hmac_iterations = 2000 # a default set by the Encryptor gem
          key = Gitlab::Application.credentials.otp_key_base
          salt = Base64.decode64(encrypted_otp_secret_salt)
          iv = Base64.decode64(encrypted_otp_secret_iv)
          cipher_text = Base64.decode64(encrypted_otp_secret)
          cipher = OpenSSL::Cipher.new('aes-256-cbc')

          cipher.decrypt
          cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(key, salt, hmac_iterations, cipher.key_len)
          cipher.iv = iv
          cipher.update(cipher_text) + cipher.final
        end
      end

      def perform
        each_sub_batch do |sub_batch|
          cte = Gitlab::SQL::CTE.new(:sub_batch, sub_batch.limit(sub_batch_size), materialized: true)

          User
            .with(cte.to_arel)
            .from(cte.alias_to(User.arel_table))
            .where(otp_required_for_login: true, otp_secret: nil)
            .limit(sub_batch_size)
            .each do |user|
            otp_secret = user.legacy_otp_secret
            user.update!(otp_secret: otp_secret) if otp_secret
          # rubocop:disable BackgroundMigration/AvoidSilentRescueExceptions -- some legacy
          # secrets were encrypted under a since-rotated otp_key_base and can never decrypt
          # (confirmed on GitLab.com). Raising here would abort the whole iteration of this
          # sub-batch, and retries would hit the same row every time given the deterministic
          # order, permanently stalling the batch for every other user in it.
          # These users' 2FA already doesn't work today (the same unrescued decrypt runs on
          # every login attempt via `User#otp_secret`, still attr_encrypted-backed pending a
          # later cleanup MR), so logging and skipping here doesn't newly break anything -- it
          # only stops that from taking the rest of the sub-batch down with it.
          rescue OpenSSL::Cipher::CipherError => e
            Gitlab::BackgroundMigration::Logger.error(
              message: 'Failed to migrate OTP secret for user',
              Labkit::Fields::GL_USER_ID => user.id,
              Labkit::Fields::ERROR_MESSAGE => e.message
            )
          end
          # rubocop:enable BackgroundMigration/AvoidSilentRescueExceptions
        end
      end
    end
  end
end

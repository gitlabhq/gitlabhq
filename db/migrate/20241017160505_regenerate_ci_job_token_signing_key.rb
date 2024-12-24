# frozen_string_literal: true

# Due to a schema cache problem reported in https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38397,
# the previous migration did not always populate the application_settings table with a CI job token
# signing key. Redo the migration if there is no key.
class RegenerateCiJobTokenSigningKey < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class ApplicationSetting < MigrationRecord
    attr_encrypted :ci_job_token_signing_key, {
      mode: :per_attribute_iv,
      key: Settings.attr_encrypted_db_key_base_32,
      algorithm: 'aes-256-gcm',
      encode: false,
      encode_iv: false
    }
  end

  def up
    ApplicationSetting.reset_column_information
    ApplicationSetting.find_each do |application_setting|
      next if application_setting.ci_job_token_signing_key.present?

      application_setting.update(ci_job_token_signing_key: OpenSSL::PKey::RSA.new(2048).to_pem)
    end
  end

  def down
    ApplicationSetting.reset_column_information
    ApplicationSetting.find_each do |application_setting|
      application_setting.update_columns(
        encrypted_ci_job_token_signing_key: nil,
        encrypted_ci_job_token_signing_key_iv: nil
      )
    end
  end
end

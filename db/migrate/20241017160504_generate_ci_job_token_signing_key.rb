# frozen_string_literal: true

class GenerateCiJobTokenSigningKey < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class ApplicationSetting < MigrationRecord
    include Gitlab::EncryptedAttribute

    attr_encrypted :ci_job_token_signing_key, {
      mode: :per_attribute_iv,
      key: :db_key_base_32,
      algorithm: 'aes-256-gcm',
      encode: false,
      encode_iv: false
    }
  end

  def up
    ApplicationSetting.reset_column_information
    ApplicationSetting.find_each do |application_setting|
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

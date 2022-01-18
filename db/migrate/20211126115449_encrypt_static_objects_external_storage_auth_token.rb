# frozen_string_literal: true

class EncryptStaticObjectsExternalStorageAuthToken < Gitlab::Database::Migration[1.0]
  class ApplicationSetting < ActiveRecord::Base
    self.table_name = 'application_settings'

    scope :encrypted_token_is_null, -> { where(static_objects_external_storage_auth_token_encrypted: nil) }
    scope :encrypted_token_is_not_null, -> { where.not(static_objects_external_storage_auth_token_encrypted: nil) }
    scope :plaintext_token_is_not_null, -> { where.not(static_objects_external_storage_auth_token: nil) }
  end

  def up
    ApplicationSetting.reset_column_information

    ApplicationSetting.encrypted_token_is_null.plaintext_token_is_not_null.find_each do |application_setting|
      next if application_setting.static_objects_external_storage_auth_token.empty?

      token_encrypted = Gitlab::CryptoHelper.aes256_gcm_encrypt(application_setting.static_objects_external_storage_auth_token)
      application_setting.update!(static_objects_external_storage_auth_token_encrypted: token_encrypted)
    end
  end

  def down
    ApplicationSetting.reset_column_information

    ApplicationSetting.encrypted_token_is_not_null.find_each do |application_setting|
      token = Gitlab::CryptoHelper.aes256_gcm_decrypt(application_setting.static_objects_external_storage_auth_token_encrypted)
      application_setting.update!(static_objects_external_storage_auth_token: token, static_objects_external_storage_auth_token_encrypted: nil)
    end
  end
end

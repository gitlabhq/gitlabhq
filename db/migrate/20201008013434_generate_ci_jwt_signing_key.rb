# frozen_string_literal: true

class GenerateCiJwtSigningKey < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  class ApplicationSetting < ActiveRecord::Base
    self.table_name = 'application_settings'

    attr_encrypted :ci_jwt_signing_key, {
      mode: :per_attribute_iv,
      key: Gitlab::Utils.ensure_utf8_size(Rails.application.secrets.db_key_base, bytes: 32.bytes),
      algorithm: 'aes-256-gcm',
      encode: true
    }
  end

  def up
    ApplicationSetting.reset_column_information

    ApplicationSetting.find_each do |application_setting|
      application_setting.update(ci_jwt_signing_key: OpenSSL::PKey::RSA.new(2048).to_pem)
    end
  end

  def down
    ApplicationSetting.reset_column_information

    ApplicationSetting.find_each do |application_setting|
      application_setting.update_columns(encrypted_ci_jwt_signing_key: nil, encrypted_ci_jwt_signing_key_iv: nil)
    end
  end
end

# frozen_string_literal: true

class SeedCloudConnectorKeys < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class ApplicationSetting < MigrationRecord
    encrypts :cloud_connector_keys
  end

  def up
    ApplicationSetting.reset_column_information
    ApplicationSetting.find_each do |application_setting|
      application_setting.cloud_connector_keys = populate_keys
      application_setting.save!
    end
  end

  def down
    ApplicationSetting.reset_column_information
    ApplicationSetting.find_each do |application_setting|
      application_setting.cloud_connector_keys = nil
      application_setting.save!
    end
  end

  def populate_keys
    old_key = Rails.application.credentials.openid_connect_signing_key
    new_key = OpenSSL::PKey::RSA.new(2048).to_pem

    [old_key, new_key]
  end
end

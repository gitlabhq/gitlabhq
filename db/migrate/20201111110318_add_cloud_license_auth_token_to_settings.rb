# frozen_string_literal: true

class AddCloudLicenseAuthTokenToSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20201111110918_add_cloud_license_auth_token_application_settings_text_limit
  def change
    add_column :application_settings, :encrypted_cloud_license_auth_token, :text
    add_column :application_settings, :encrypted_cloud_license_auth_token_iv, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end

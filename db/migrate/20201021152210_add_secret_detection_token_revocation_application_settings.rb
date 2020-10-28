# frozen_string_literal: true

class AddSecretDetectionTokenRevocationApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    add_column :application_settings, :secret_detection_token_revocation_enabled, :boolean, default: false, null: false
    add_column :application_settings, :secret_detection_token_revocation_url, :text, null: true # rubocop:disable Migration/AddLimitToTextColumns

    add_column :application_settings, :encrypted_secret_detection_token_revocation_token, :text
    add_column :application_settings, :encrypted_secret_detection_token_revocation_token_iv, :text
  end

  def down
    remove_column :application_settings, :secret_detection_token_revocation_enabled
    remove_column :application_settings, :secret_detection_token_revocation_url

    remove_column :application_settings, :encrypted_secret_detection_token_revocation_token
    remove_column :application_settings, :encrypted_secret_detection_token_revocation_token_iv
  end
end

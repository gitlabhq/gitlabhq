# frozen_string_literal: true

class AddSecretDetectionServiceAuthTokenToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone "17.6"

  def up
    add_column :application_settings, :encrypted_secret_detection_service_auth_token, :binary, if_not_exists: true
    add_column :application_settings, :encrypted_secret_detection_service_auth_token_iv, :binary, if_not_exists: true
  end

  def down
    remove_column :application_settings, :encrypted_secret_detection_service_auth_token, if_exists: true
    remove_column :application_settings, :encrypted_secret_detection_service_auth_token_iv, if_exists: true
  end
end

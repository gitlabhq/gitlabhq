# frozen_string_literal: true

class AddSlackSigningKeyToApplicationSettings < Gitlab::Database::Migration[2.0]
  def change
    add_column :application_settings, :encrypted_slack_app_signing_secret, :binary
    add_column :application_settings, :encrypted_slack_app_signing_secret_iv, :binary
  end
end

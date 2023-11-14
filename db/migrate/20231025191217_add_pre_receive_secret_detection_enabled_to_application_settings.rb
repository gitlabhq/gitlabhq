# frozen_string_literal: true

class AddPreReceiveSecretDetectionEnabledToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  def change
    add_column :application_settings, :pre_receive_secret_detection_enabled, :boolean, null: false, default: false
  end
end

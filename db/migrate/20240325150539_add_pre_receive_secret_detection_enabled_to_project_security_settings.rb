# frozen_string_literal: true

class AddPreReceiveSecretDetectionEnabledToProjectSecuritySettings < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  enable_lock_retries!
  TABLE_NAME = :project_security_settings
  COLUMN_NAME = :pre_receive_secret_detection_enabled

  def up
    add_column TABLE_NAME, COLUMN_NAME, :boolean, null: false,
      default: false
  end

  def down
    remove_column TABLE_NAME, COLUMN_NAME
  end
end

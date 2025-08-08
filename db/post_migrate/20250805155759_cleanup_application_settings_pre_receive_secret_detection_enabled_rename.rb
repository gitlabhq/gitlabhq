# frozen_string_literal: true

class CleanupApplicationSettingsPreReceiveSecretDetectionEnabledRename < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :application_settings, :pre_receive_secret_detection_enabled,
      :secret_push_protection_available
  end

  def down
    undo_cleanup_concurrent_column_rename :application_settings, :pre_receive_secret_detection_enabled,
      :secret_push_protection_available
  end
end

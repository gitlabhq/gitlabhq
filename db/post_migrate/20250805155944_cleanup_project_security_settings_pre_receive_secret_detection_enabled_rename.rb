# frozen_string_literal: true

class CleanupProjectSecuritySettingsPreReceiveSecretDetectionEnabledRename < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :project_security_settings, :pre_receive_secret_detection_enabled,
      :secret_push_protection_enabled
  end

  def down
    undo_cleanup_concurrent_column_rename :project_security_settings, :pre_receive_secret_detection_enabled,
      :secret_push_protection_enabled, batch_column_name: :project_id
  end
end

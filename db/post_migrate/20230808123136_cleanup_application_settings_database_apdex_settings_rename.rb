# frozen_string_literal: true

class CleanupApplicationSettingsDatabaseApdexSettingsRename < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename(
      :application_settings,
      :database_apdex_settings,
      :prometheus_alert_db_indicators_settings
    )
  end

  def down
    undo_cleanup_concurrent_column_rename(
      :application_settings,
      :database_apdex_settings,
      :prometheus_alert_db_indicators_settings
    )
  end
end

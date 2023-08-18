# frozen_string_literal: true

class RenameApplicationSettingsDatabaseApdexSettings < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    rename_column_concurrently(
      :application_settings,
      :database_apdex_settings,
      :prometheus_alert_db_indicators_settings
    )
  end

  def down
    undo_rename_column_concurrently(
      :application_settings,
      :database_apdex_settings,
      :prometheus_alert_db_indicators_settings
    )
  end
end

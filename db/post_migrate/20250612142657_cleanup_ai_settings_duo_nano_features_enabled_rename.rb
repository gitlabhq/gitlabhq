# frozen_string_literal: true

class CleanupAiSettingsDuoNanoFeaturesEnabledRename < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :ai_settings, :duo_nano_features_enabled,
      :duo_core_features_enabled
  end

  def down
    undo_cleanup_concurrent_column_rename :ai_settings, :duo_nano_features_enabled,
      :duo_core_features_enabled
  end
end

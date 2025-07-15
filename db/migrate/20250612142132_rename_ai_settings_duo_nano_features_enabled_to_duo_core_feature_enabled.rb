# frozen_string_literal: true

class RenameAiSettingsDuoNanoFeaturesEnabledToDuoCoreFeatureEnabled < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  disable_ddl_transaction!

  def up
    rename_column_concurrently :ai_settings, :duo_nano_features_enabled,
      :duo_core_features_enabled
  end

  def down
    undo_rename_column_concurrently :ai_settings, :duo_nano_features_enabled,
      :duo_core_features_enabled
  end
end

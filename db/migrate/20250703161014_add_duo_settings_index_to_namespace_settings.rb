# frozen_string_literal: true

class AddDuoSettingsIndexToNamespaceSettings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.2'

  TABLE = :namespace_settings
  COLUMNS = [:duo_features_enabled, :lock_duo_features_enabled]
  INDEX = "index_namespace_settings_on_duo_features"

  def up
    add_concurrent_index TABLE, COLUMNS,
      where: 'duo_features_enabled IS NOT NULL', include: :namespace_id,
      name: INDEX
  end

  def down
    remove_concurrent_index_by_name TABLE, INDEX
  end
end

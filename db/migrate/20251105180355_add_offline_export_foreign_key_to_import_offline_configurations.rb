# frozen_string_literal: true

class AddOfflineExportForeignKeyToImportOfflineConfigurations < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    add_concurrent_foreign_key :import_offline_configurations, :import_offline_exports, column: :offline_export_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :import_offline_configurations, column: :offline_export_id
    end
  end
end

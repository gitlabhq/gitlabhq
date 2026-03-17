# frozen_string_literal: true

class MakeOfflineExportIdNullableOnImportOfflineConfigurations < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.10'

  def up
    with_lock_retries do
      change_column_null :import_offline_configurations, :offline_export_id, true
    end

    add_multi_column_not_null_constraint(:import_offline_configurations, :offline_export_id, :bulk_import_id)
  end

  def down
    with_lock_retries do
      change_column_null :import_offline_configurations, :offline_export_id, false
    end

    remove_multi_column_not_null_constraint(:import_offline_configurations, :offline_export_id, :bulk_import_id)
  end
end

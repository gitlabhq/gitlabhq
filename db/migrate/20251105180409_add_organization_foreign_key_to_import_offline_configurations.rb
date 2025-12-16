# frozen_string_literal: true

class AddOrganizationForeignKeyToImportOfflineConfigurations < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    add_concurrent_foreign_key :import_offline_configurations, :organizations, column: :organization_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :import_offline_configurations, column: :organization_id
    end
  end
end

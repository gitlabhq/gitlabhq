# frozen_string_literal: true

class AddCatalogResourceFkToCatalogResourceComponentLastUsages < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  def up
    add_concurrent_foreign_key :catalog_resource_component_last_usages, :catalog_resources,
      column: :catalog_resource_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :catalog_resource_component_last_usages, column: :catalog_resource_id
    end
  end
end

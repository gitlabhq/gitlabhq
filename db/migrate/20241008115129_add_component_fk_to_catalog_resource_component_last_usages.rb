# frozen_string_literal: true

class AddComponentFkToCatalogResourceComponentLastUsages < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  def up
    add_concurrent_foreign_key :catalog_resource_component_last_usages, :catalog_resource_components,
      column: :component_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :catalog_resource_component_last_usages, column: :component_id
    end
  end
end

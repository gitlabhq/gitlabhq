# frozen_string_literal: true

class AddProjectFkToCatalogResourceComponentLastUsages < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.6'

  def up
    add_concurrent_foreign_key :catalog_resource_component_last_usages, :projects,
      column: :component_project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :catalog_resource_component_last_usages, column: :component_project_id
    end
  end
end

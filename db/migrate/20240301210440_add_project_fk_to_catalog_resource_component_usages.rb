# frozen_string_literal: true

class AddProjectFkToCatalogResourceComponentUsages < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  milestone '16.10'

  disable_ddl_transaction!

  def up
    add_concurrent_partitioned_foreign_key :p_catalog_resource_component_usages, :projects,
      column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :p_catalog_resource_component_usages, column: :project_id
    end
  end
end

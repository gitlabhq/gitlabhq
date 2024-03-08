# frozen_string_literal: true

class AddComponentFkToCatalogResourceComponentUsages < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  milestone '16.10'

  disable_ddl_transaction!

  def up
    add_concurrent_partitioned_foreign_key :p_catalog_resource_component_usages, :catalog_resource_components,
      column: :component_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :p_catalog_resource_component_usages, column: :component_id
    end
  end
end

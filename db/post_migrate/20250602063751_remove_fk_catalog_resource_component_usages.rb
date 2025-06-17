# frozen_string_literal: true

class RemoveFkCatalogResourceComponentUsages < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  milestone '18.1'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(
        :p_catalog_resource_component_usages,
        :projects,
        column: :project_id,
        reverse_lock_order: true)
    end

    with_lock_retries do
      remove_foreign_key_if_exists(
        :p_catalog_resource_component_usages,
        :catalog_resources,
        column: :catalog_resource_id)
    end

    with_lock_retries do
      remove_foreign_key_if_exists(
        :p_catalog_resource_component_usages,
        :catalog_resource_components,
        column: :component_id)
    end
  end

  def down
    add_concurrent_partitioned_foreign_key(
      :p_catalog_resource_component_usages,
      :projects,
      column: :project_id,
      on_delete: :cascade,
      reverse_lock_order: true
    )

    add_concurrent_partitioned_foreign_key(
      :p_catalog_resource_component_usages,
      :catalog_resources,
      column: :catalog_resource_id,
      on_delete: :cascade
    )

    add_concurrent_partitioned_foreign_key(
      :p_catalog_resource_component_usages,
      :catalog_resource_components,
      column: :component_id,
      on_delete: :cascade
    )
  end
end

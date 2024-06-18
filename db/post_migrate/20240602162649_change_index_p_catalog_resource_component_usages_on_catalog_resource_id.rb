# frozen_string_literal: true

class ChangeIndexPCatalogResourceComponentUsagesOnCatalogResourceId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.1'

  disable_ddl_transaction!

  TABLE_NAME = :p_catalog_resource_component_usages
  COLUMN_NAMES = [:catalog_resource_id, :used_by_project_id, :used_date]
  INDEX_NAME = 'idx_component_usages_on_catalog_resource_used_by_proj_used_date'

  OLD_COLUMN_NAMES = [:catalog_resource_id]
  OLD_INDEX_NAME = 'idx_p_catalog_resource_component_usages_on_catalog_resource_id'

  def up
    add_concurrent_partitioned_index(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME)
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_partitioned_index(TABLE_NAME, OLD_COLUMN_NAMES, name: OLD_INDEX_NAME)
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end

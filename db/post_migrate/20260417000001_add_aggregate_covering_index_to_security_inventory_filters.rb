# frozen_string_literal: true

class AddAggregateCoveringIndexToSecurityInventoryFilters < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.0'

  TABLE_NAME = :security_inventory_filters
  NEW_INDEX_NAME = 'idx_sec_inv_filters_traversal_project_ids_aggregate_booleans'
  OLD_INDEX_NAME = 'idx_security_inventory_filters_traversal_ids_unarchived_project'

  def up
    add_concurrent_index(
      TABLE_NAME,
      [:traversal_ids, :project_id],
      name: NEW_INDEX_NAME,
      include: [:has_scanners, :has_failed_or_warning, :has_stale],
      where: 'NOT archived'
    )

    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(
      TABLE_NAME,
      [:traversal_ids, :project_id],
      name: OLD_INDEX_NAME,
      where: 'NOT archived'
    )

    remove_concurrent_index_by_name(TABLE_NAME, NEW_INDEX_NAME)
  end
end

# frozen_string_literal: true

class AddAnalyzerStatusCoveringIndexToSecurityInventoryFilters < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  TABLE_NAME = :security_inventory_filters
  MERGED_INDEX_NAME = 'idx_sec_inv_filters_traversal_proj_covering'
  OLD_INDEX_NAME = 'idx_sec_inv_filters_traversal_project_ids_aggregate_booleans'

  def up
    add_concurrent_index(
      TABLE_NAME,
      %i[traversal_ids project_id],
      name: MERGED_INDEX_NAME,
      include: %i[has_scanners has_failed_or_warning has_stale sast dependency_scanning secret_detection],
      where: 'NOT archived'
    )

    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(
      TABLE_NAME,
      %i[traversal_ids project_id],
      name: OLD_INDEX_NAME,
      include: %i[has_scanners has_failed_or_warning has_stale],
      where: 'NOT archived'
    )

    remove_concurrent_index_by_name(TABLE_NAME, MERGED_INDEX_NAME)
  end
end

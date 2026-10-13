# frozen_string_literal: true

class AddTriageCoveringIndexToSecurityInventoryFilters < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.5'

  TABLE_NAME = :security_inventory_filters
  NEW_INDEX_NAME = 'idx_sec_inv_filters_traversal_proj_covering_triage'
  OLD_INDEX_NAME = 'idx_sec_inv_filters_traversal_proj_covering'

  def up
    add_concurrent_index(
      TABLE_NAME,
      %i[traversal_ids project_id],
      name: NEW_INDEX_NAME,
      include: %i[
        has_scanners has_failed_or_warning has_stale sast dependency_scanning secret_detection
        triage_capabilities_on triage_capabilities_auto
      ],
      where: 'NOT archived'
    )

    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(
      TABLE_NAME,
      %i[traversal_ids project_id],
      name: OLD_INDEX_NAME,
      include: %i[has_scanners has_failed_or_warning has_stale sast dependency_scanning secret_detection],
      where: 'NOT archived'
    )

    remove_concurrent_index_by_name(TABLE_NAME, NEW_INDEX_NAME)
  end
end

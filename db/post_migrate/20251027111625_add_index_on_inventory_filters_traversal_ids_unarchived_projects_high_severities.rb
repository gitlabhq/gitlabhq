# frozen_string_literal: true

class AddIndexOnInventoryFiltersTraversalIdsUnarchivedProjectsHighSeverities < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  TABLE_NAME = :security_inventory_filters
  INDEX_NAME = "idx_sec_inv_filters_traversals_unarchived_proj_severities_sort"

  def up
    add_concurrent_index(
      TABLE_NAME,
      [:traversal_ids, :project_id, :id],
      order: { traversal_ids: :asc, project_id: :asc, id: :desc },
      name: INDEX_NAME,
      where: 'NOT archived AND (critical > 0 OR high > 0)'
    )
  end

  def down
    remove_concurrent_index_by_name(
      TABLE_NAME,
      INDEX_NAME
    )
  end
end

# frozen_string_literal: true

class AddIndexOnInventoryFiltersTraversalIdsUnarchivedProjects < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  TABLE_NAME = :security_inventory_filters
  INDEX_NAME = "idx_security_inventory_filters_traversal_ids_unarchived_project"

  def up
    add_concurrent_index(
      TABLE_NAME,
      [:traversal_ids, :project_id],
      name: INDEX_NAME,
      where: 'NOT archived'
    )
  end

  def down
    remove_concurrent_index_by_name(
      TABLE_NAME,
      INDEX_NAME
    )
  end
end

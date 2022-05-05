# frozen_string_literal: true

class RecreateIndexForProjectGroupLinkWithGroupIdAndProjectId < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'index_project_group_links_on_group_id'
  NEW_INDEX_NAME = 'index_project_group_links_on_group_id_and_project_id'

  def up
    add_concurrent_index :project_group_links, [:group_id, :project_id], name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :project_group_links, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :project_group_links, [:group_id], name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :project_group_links, NEW_INDEX_NAME
  end
end

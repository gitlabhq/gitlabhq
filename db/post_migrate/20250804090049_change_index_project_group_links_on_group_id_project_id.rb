# frozen_string_literal: true

class ChangeIndexProjectGroupLinksOnGroupIdProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  UNIQUE_INDEX_NAME = 'unique_index_project_group_links_on_group_id_and_project_id'
  INDEX_NAME = 'index_project_group_links_on_group_id_and_project_id'

  def up
    add_concurrent_index :project_group_links, [:group_id, :project_id], name: UNIQUE_INDEX_NAME, unique: true
    remove_concurrent_index_by_name :project_group_links, INDEX_NAME
  end

  def down
    add_concurrent_index :project_group_links, [:group_id, :project_id], name: INDEX_NAME
    remove_concurrent_index_by_name :project_group_links, UNIQUE_INDEX_NAME
  end
end

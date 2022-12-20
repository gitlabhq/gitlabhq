# frozen_string_literal: true

class AddSyncPartStep2OfIndexNamespacesOnPathForTopLevelNonProjects < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = 'namespaces'
  INDEX_NAME = 'index_namespaces_on_path_for_top_level_non_projects'
  COLUMN = "lower((path)::text)"
  CONDITIONS = "(parent_id IS NULL AND type::text <> 'Project'::text)"

  def up
    add_concurrent_index TABLE_NAME, COLUMN, name: INDEX_NAME, where: CONDITIONS
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end

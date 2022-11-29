# frozen_string_literal: true

class AddIndexForPathsOnNonProjects < Gitlab::Database::Migration[2.0]
  TABLE_NAME = 'namespaces'
  INDEX_NAME = 'index_namespaces_on_path_for_top_level_non_projects'
  COLUMN = "(lower(path::text))"
  CONDITIONS = "(parent_id IS NULL AND type::text <> 'Project'::text)"

  def up
    prepare_async_index TABLE_NAME, COLUMN, name: INDEX_NAME, where: CONDITIONS
  end

  def down
    unprepare_async_index TABLE_NAME, COLUMN, name: INDEX_NAME
  end
end

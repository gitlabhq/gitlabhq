# frozen_string_literal: true

class AddTraversalPathProjectionToProjectNamespaceTraversalPaths < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE project_namespace_traversal_paths
      MODIFY SETTING deduplicate_merge_projection_mode = 'rebuild';
    SQL

    execute <<~SQL
      ALTER TABLE project_namespace_traversal_paths
        ADD PROJECTION IF NOT EXISTS by_traversal_path
        (
          SELECT *
          ORDER BY traversal_path
        );
    SQL

    execute <<~SQL
      ALTER TABLE project_namespace_traversal_paths MATERIALIZE PROJECTION by_traversal_path;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE project_namespace_traversal_paths DROP PROJECTION IF EXISTS by_traversal_path
      SETTINGS mutations_sync = 0;
    SQL
  end
end

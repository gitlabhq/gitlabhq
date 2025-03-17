# frozen_string_literal: true

class CreateProjectNamespaceTraversalPathsTable < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS project_namespace_traversal_paths (
        id Int64 DEFAULT 0,
        traversal_path String DEFAULT '0/',
        version DateTime64(6, 'UTC') DEFAULT NOW(),
        deleted Boolean DEFAULT false
      )
      ENGINE=ReplacingMergeTree(version, deleted)
      PRIMARY KEY id
      SETTINGS index_granularity = 512;
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS project_namespace_traversal_paths
    SQL
  end
end

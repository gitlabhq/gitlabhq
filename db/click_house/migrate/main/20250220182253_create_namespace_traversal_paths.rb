# frozen_string_literal: true

class CreateNamespaceTraversalPaths < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE namespace_traversal_paths (
        id Int64 DEFAULT 0,
        traversal_path String DEFAULT '0/',
        version DateTime64(6, 'UTC') DEFAULT NOW(),
        deleted Boolean DEFAULT false
      )
      ENGINE=ReplacingMergeTree(version, deleted)
      PRIMARY KEY id
      SETTINGS index_granularity = 512; -- lower granularity so id lookups use less I/O
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS namespace_traversal_paths
    SQL
  end
end

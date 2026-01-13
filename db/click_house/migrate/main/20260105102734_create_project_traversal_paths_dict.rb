# frozen_string_literal: true

class CreateProjectTraversalPathsDict < ClickHouse::Migration
  def up
    definition = <<~SQL
      CREATE DICTIONARY IF NOT EXISTS project_traversal_paths_dict
      (
          `id` UInt64,
          `traversal_path` String
      )
      PRIMARY KEY id
        SOURCE(
          CLICKHOUSE(
            QUERY '
              SELECT id, traversal_path FROM (
                SELECT id, traversal_path
                FROM (
                  SELECT
                    id,
                    argMax(traversal_path, version) AS traversal_path,
                    argMax(deleted, version) AS deleted
                    FROM project_namespace_traversal_paths
                  GROUP BY id
                )
                WHERE deleted = false
              )
            '
          )
        )
        LIFETIME(MIN 60 MAX 300)
        LAYOUT(CACHE(SIZE_IN_CELLS 5000000))
    SQL

    create_dictionary(definition, source_tables: ['project_namespace_traversal_paths'])
  end

  def down
    execute('DROP DICTIONARY project_traversal_paths_dict')
  end
end

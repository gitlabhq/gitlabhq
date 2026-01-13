# frozen_string_literal: true

class CreateOrganizationTraversalPathsDict < ClickHouse::Migration
  def up
    definition = <<~SQL
      CREATE DICTIONARY IF NOT EXISTS organization_traversal_paths_dict
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
                    concat(toString(id), ''/'') AS traversal_path,
                    argMax(_siphon_deleted, _siphon_replicated_at) AS _siphon_deleted
                    FROM siphon_organizations
                  GROUP BY id
                )
                WHERE _siphon_deleted = false
              )
            '
          )
        )
        LIFETIME(MIN 60 MAX 300)
        LAYOUT(CACHE(SIZE_IN_CELLS 100000))
    SQL

    create_dictionary(definition, source_tables: ['siphon_organizations'])
  end

  def down
    execute('DROP DICTIONARY organization_traversal_paths_dict')
  end
end

# frozen_string_literal: true

class CreateNamespaceOrganizationsDict < ClickHouse::Migration
  # A root namespace is only ever assigned to one organization, so the latest version wins and rows
  # never need a deleted flag: a root namespace that disappears from Postgres simply stops being
  # refreshed, and the rebuild leaves such rows at the sentinel.
  def up
    definition = <<~SQL
      CREATE DICTIONARY IF NOT EXISTS namespace_organizations_dict
      (
          `root_namespace_id` UInt64,
          `organization_id` UInt64
      )
      PRIMARY KEY root_namespace_id
        SOURCE(
          CLICKHOUSE(
            QUERY '
              SELECT root_namespace_id, argMax(organization_id, version) AS organization_id
              FROM namespace_organizations
              GROUP BY root_namespace_id
            '
          )
        )
        LIFETIME(MIN 60 MAX 300)
        LAYOUT(HASHED())
    SQL

    create_dictionary(definition, source_tables: ['namespace_organizations'])
  end

  def down
    execute('DROP DICTIONARY IF EXISTS namespace_organizations_dict')
  end
end

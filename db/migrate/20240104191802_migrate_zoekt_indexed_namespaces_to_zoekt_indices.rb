# frozen_string_literal: true

class MigrateZoektIndexedNamespacesToZoektIndices < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '16.8'

  INSERTED_COLUMNS = %w[
    zoekt_enabled_namespace_id
    namespace_id
    zoekt_node_id
    state
    created_at
    updated_at
  ].join(',')

  STATE_READY = 10

  def up
    connection.execute(<<~SQL)
      WITH indexed_namespaces AS (
        (SELECT DISTINCT ON (namespace_id) namespace_id, search, zoekt_node_id
        FROM zoekt_indexed_namespaces ORDER BY namespace_id, search)
      )

      INSERT INTO zoekt_indices (#{INSERTED_COLUMNS})
      SELECT
        zoekt_enabled_namespaces.id,
        indexed_namespaces.namespace_id,
        indexed_namespaces.zoekt_node_id,
        #{STATE_READY},
        NOW(),
        NOW()
      FROM zoekt_enabled_namespaces
      JOIN indexed_namespaces ON indexed_namespaces.namespace_id = zoekt_enabled_namespaces.root_namespace_id
    SQL
  end

  def down
    connection.execute(<<~SQL)
      DELETE FROM zoekt_indices
    SQL
  end
end

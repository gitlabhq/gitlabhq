# frozen_string_literal: true

class MigrateZoektIndexedNamespacesToZoektEnabledNamespaces < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '16.8'

  INSERTED_COLUMNS = %w[
    root_namespace_id
    search
    created_at
    updated_at
  ].join(',')

  def up
    connection.execute(<<~SQL)
      INSERT INTO zoekt_enabled_namespaces (#{INSERTED_COLUMNS})
      (SELECT DISTINCT ON (namespace_id) namespace_id, search, created_at, updated_at
      FROM zoekt_indexed_namespaces ORDER BY namespace_id, search)
    SQL
  end

  def down
    connection.execute(<<~SQL)
      DELETE FROM zoekt_enabled_namespaces
    SQL
  end
end

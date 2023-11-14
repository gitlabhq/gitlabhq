# frozen_string_literal: true

class BackfillZoektNodeIdOnIndexedNamespaces < Gitlab::Database::Migration[2.2]
  milestone '16.6'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    sql = <<-SQL
      UPDATE zoekt_indexed_namespaces
      SET zoekt_node_id = (SELECT id FROM zoekt_nodes ORDER BY created_at DESC LIMIT 1)
    SQL

    execute(sql)
  end

  def down
    # no-op
  end
end

# frozen_string_literal: true

class MigrateZoektShardsToZoektNodes < Gitlab::Database::Migration[2.2]
  milestone '16.6'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  SELECTED_COLUMNS = %w[
    index_base_url
    search_base_url
    uuid
    used_bytes
    total_bytes
    metadata
    last_seen_at
    created_at
    updated_at
  ].join(',')

  def up
    connection.execute(<<~SQL)
      INSERT INTO zoekt_nodes (#{SELECTED_COLUMNS})
      SELECT #{SELECTED_COLUMNS}
      FROM zoekt_shards
    SQL
  end

  def down
    connection.execute(<<~SQL)
      DELETE FROM zoekt_nodes
    SQL
  end
end

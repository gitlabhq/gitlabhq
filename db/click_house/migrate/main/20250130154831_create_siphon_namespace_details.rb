# frozen_string_literal: true

class CreateSiphonNamespaceDetails < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_namespace_details
      (
        namespace_id Int64,
        created_at Nullable(DateTime64(6, 'UTC')),
        updated_at Nullable(DateTime64(6, 'UTC')),
        cached_markdown_version Nullable(Int64),
        description Nullable(String),
        description_html Nullable(String),
        creator_id Nullable(Int64),
        deleted_at Nullable(DateTime64(6, 'UTC')),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY namespace_id
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_namespace_details
    SQL
  end
end

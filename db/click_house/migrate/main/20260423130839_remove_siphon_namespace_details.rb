# frozen_string_literal: true

class RemoveSiphonNamespaceDetails < ClickHouse::Migration
  def up
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_namespace_details
    SQL
  end

  def down
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
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
        _siphon_deleted Bool DEFAULT FALSE,
        state_metadata String DEFAULT '{}',
        deletion_scheduled_at Nullable(DateTime64(6, 'UTC'))
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY namespace_id
      SETTINGS index_granularity = 2048
    SQL
  end
end

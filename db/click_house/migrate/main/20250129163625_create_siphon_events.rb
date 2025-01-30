# frozen_string_literal: true

class CreateSiphonEvents < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_events
      (
        project_id Nullable(Int64),
        author_id Int64,
        created_at DateTime64(6, 'UTC'),
        updated_at DateTime64(6, 'UTC'),
        action Int8,
        target_type LowCardinality(String) DEFAULT '',
        group_id Nullable(Int64),
        fingerprint Nullable(String),
        id Int64,
        target_id Nullable(Int64),
        imported_from Int8 DEFAULT 0,
        personal_namespace_id Nullable(Int64),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY id
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_events
    SQL
  end
end

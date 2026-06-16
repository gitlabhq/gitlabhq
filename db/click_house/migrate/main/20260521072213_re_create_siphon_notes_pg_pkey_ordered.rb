# frozen_string_literal: true

class ReCreateSiphonNotesPgPkeyOrdered < ClickHouse::Migration
  def up
    execute "DROP VIEW IF EXISTS siphon_notes_pg_pkey_ordered_mv"
    execute "DROP TABLE IF EXISTS siphon_notes_pg_pkey_ordered"

    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_notes_pg_pkey_ordered
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        noteable_type LowCardinality(String),
        noteable_id Int64,
        traversal_path String DEFAULT '0/' CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1))
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (id, noteable_type, noteable_id, traversal_path)
      ORDER BY (id, noteable_type, noteable_id, traversal_path)
      SETTINGS index_granularity = 1024
    SQL

    execute <<-SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS siphon_notes_pg_pkey_ordered_mv
      TO siphon_notes_pg_pkey_ordered
      AS
      SELECT
        id,
        traversal_path,
        noteable_type,
        noteable_id,
        _siphon_replicated_at,
        _siphon_deleted
      FROM siphon_notes
    SQL
  end

  def down
    execute "DROP VIEW IF EXISTS siphon_notes_pg_pkey_ordered_mv"
    execute "DROP TABLE IF EXISTS siphon_notes_pg_pkey_ordered"
  end
end

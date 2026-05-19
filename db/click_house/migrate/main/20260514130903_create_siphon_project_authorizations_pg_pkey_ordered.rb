# frozen_string_literal: true

class CreateSiphonProjectAuthorizationsPgPkeyOrdered < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_project_authorizations_pg_pkey_ordered
      (
        user_id Int64 CODEC(DoubleDelta, ZSTD),
        project_id Int64 CODEC(DoubleDelta, ZSTD),
        access_level Int64 CODEC(DoubleDelta, ZSTD),
        traversal_path String DEFAULT '0/' CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1))
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (user_id, project_id, access_level, traversal_path)
      ORDER BY (user_id, project_id, access_level, traversal_path)
      SETTINGS index_granularity = 1024
    SQL

    execute <<-SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS siphon_project_authorizations_pg_pkey_ordered_mv
      TO siphon_project_authorizations_pg_pkey_ordered
      AS
      SELECT
        user_id,
        project_id,
        access_level,
        traversal_path,
        _siphon_replicated_at,
        _siphon_deleted
      FROM siphon_project_authorizations
    SQL
  end

  def down
    execute "DROP VIEW IF EXISTS siphon_project_authorizations_pg_pkey_ordered_mv"
    execute "DROP TABLE IF EXISTS siphon_project_authorizations_pg_pkey_ordered"
  end
end

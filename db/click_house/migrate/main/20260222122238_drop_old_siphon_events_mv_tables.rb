# frozen_string_literal: true

class DropOldSiphonEventsMvTables < ClickHouse::Migration
  def up
    execute 'DROP VIEW IF EXISTS contributions_new_mv'
    execute 'DROP VIEW IF EXISTS events_new_mv'
    execute 'DROP TABLE IF EXISTS contributions_new'
    execute 'DROP TABLE IF EXISTS events_new'
    execute 'DROP TABLE IF EXISTS siphon_events'
  end

  def down
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

    execute <<-SQL
      CREATE TABLE IF NOT EXISTS events_new (
        id Int64 DEFAULT 0,
        path String DEFAULT '0/',
        author_id UInt64 DEFAULT 0,
        action UInt8 DEFAULT 0,
        target_type LowCardinality(String) DEFAULT '',
        target_id UInt64 DEFAULT 0,
        created_at DateTime64(6, 'UTC') DEFAULT now(),
        updated_at DateTime64(6, 'UTC') DEFAULT now(),
        version DateTime64(6, 'UTC') DEFAULT NOW(),
        deleted Boolean DEFAULT false
      )
      ENGINE=ReplacingMergeTree(version, deleted)
      PRIMARY KEY id
      ORDER BY (id)
      PARTITION BY toYear(created_at)
    SQL

    execute <<-SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS events_new_mv
      TO events_new
      AS
      WITH cte AS (
      SELECT * FROM siphon_events
      ), group_lookups AS (
        SELECT id, traversal_path
        FROM namespace_traversal_paths
        WHERE id IN (SELECT DISTINCT group_id FROM cte)
      ), project_lookups AS (
        SELECT id, traversal_path
        FROM project_namespace_traversal_paths
        WHERE id IN (SELECT DISTINCT project_id FROM cte)
      )
      SELECT
          cte.id AS id,
          CASE
              WHEN cte.project_id != 0 THEN project_lookups.traversal_path
              WHEN cte.group_id != 0 THEN group_lookups.traversal_path
              ELSE '0/'
          END AS path,
          cte.author_id AS author_id,
          cte.action AS action,
          cte.target_type AS target_type,
          cte.target_id AS target_id,
          cte.created_at AS created_at,
          cte.updated_at AS updated_at,
          cte._siphon_replicated_at AS version,
          cte._siphon_deleted AS deleted
      FROM cte
      LEFT JOIN group_lookups ON group_lookups.id=cte.group_id
      LEFT JOIN project_lookups on project_lookups.id=cte.project_id
    SQL

    execute <<~SQL
      CREATE TABLE IF NOT EXISTS contributions_new
      (
        id UInt64 DEFAULT 0,
        path String DEFAULT '',
        author_id UInt64 DEFAULT 0,
        target_type LowCardinality(String) DEFAULT '',
        action UInt8 DEFAULT 0,
        created_at Date DEFAULT toDate(now64()),
        updated_at DateTime64(6, 'UTC') DEFAULT now64(),
        version DateTime64(6, 'UTC') DEFAULT now(),
        deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(version, deleted)
      ORDER BY (path, created_at, author_id, id)
      PARTITION BY toYear(created_at);
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS contributions_new_mv
      TO contributions_new
      AS
      SELECT
        id,
        argMax(path, events_new.version) as path,
        argMax(author_id, events_new.version) as author_id,
        argMax(target_type, events_new.version) as target_type,
        argMax(action, events_new.version) as action,
        argMax(date(created_at), events_new.version) as created_at,
        argMax(date(updated_at), events_new.version) as updated_at,
        argMax(deleted, events_new.version) as deleted,
        max(events_new.version) as version
      FROM events_new
      WHERE (("events_new"."action" IN (5, 6) AND "events_new"."target_type" = '')
        OR ("events_new"."action" IN (1, 3, 7, 12)
          AND "events_new"."target_type" IN ('MergeRequest', 'Issue', 'WorkItem')))
      GROUP BY id
    SQL
  end
end

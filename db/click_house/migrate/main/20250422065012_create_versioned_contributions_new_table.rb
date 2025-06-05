# frozen_string_literal: true

class CreateVersionedContributionsNewTable < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS contributions_new_tmp
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
      DROP VIEW IF EXISTS contributions_new_mv
    SQL

    execute <<~SQL
      EXCHANGE TABLES contributions_new_tmp AND contributions_new
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

    execute <<~SQL
      DROP TABLE IF EXISTS contributions_new_tmp
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS contributions_new
    SQL

    execute <<~SQL
      DROP VIEW IF EXISTS contributions_new_mv
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
        updated_at DateTime64(6, 'UTC') DEFAULT now64()
      )
      ENGINE = ReplacingMergeTree
      ORDER BY (path, created_at, author_id, id)
      PARTITION BY toYear(created_at);
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS contributions_new_mv
      TO contributions_new
      AS
      SELECT
        id,
        argMax(path, events_new.updated_at) as path,
        argMax(author_id, events_new.updated_at) as author_id,
        argMax(target_type, events_new.updated_at) as target_type,
        argMax(action, events_new.updated_at) as action,
        argMax(date(created_at), events_new.updated_at) as created_at,
        max(events_new.updated_at) as updated_at
      FROM events_new
      WHERE (("events_new"."action" IN (5, 6) AND "events_new"."target_type" = '')
        OR ("events_new"."action" IN (1, 3, 7, 12)
          AND "events_new"."target_type" IN ('MergeRequest', 'Issue', 'WorkItem')))
      GROUP BY id
    SQL
  end
end

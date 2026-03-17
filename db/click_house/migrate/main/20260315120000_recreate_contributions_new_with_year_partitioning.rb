# frozen_string_literal: true

class RecreateContributionsNewWithYearPartitioning < ClickHouse::Migration
  def up
    execute 'DROP VIEW IF EXISTS contributions_new_mv'
    execute 'DROP TABLE IF EXISTS contributions_new'

    execute <<~SQL
      CREATE TABLE contributions_new
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        path String CODEC(ZSTD(3)),
        author_id Int64 CODEC(DoubleDelta, ZSTD),
        target_type LowCardinality(String) DEFAULT '',
        action Int16 DEFAULT 0,
        created_at DateTime64(6, 'UTC') DEFAULT now64(),
        updated_at DateTime64(6, 'UTC') DEFAULT now64(),
        version DateTime64(6, 'UTC') DEFAULT now64() CODEC(ZSTD(1)),
        deleted Bool DEFAULT FALSE CODEC(ZSTD(1))
      )
      ENGINE = ReplacingMergeTree(version, deleted)
      ORDER BY (path, created_at, author_id, id)
      PARTITION BY toYear(created_at)
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW contributions_new_mv
      TO contributions_new
      AS
      WITH
        base AS (SELECT * FROM siphon_events
        WHERE
          (
            (
            action IN (5, 6) AND target_type = ''
            )
            OR
            (
               action IN (1, 3, 7, 12) AND
               target_type IN ('MergeRequest', 'Issue', 'WorkItem')
            )
          )
        )
      SELECT
        base.id AS id,
        base.path AS path,
        base.author_id AS author_id,
        base.target_type AS target_type,
        base.action AS action,
        base.created_at AS created_at,
        base.updated_at AS updated_at,
        base._siphon_replicated_at AS version,
        base._siphon_deleted AS deleted
      FROM base
    SQL
  end

  def down
    execute 'DROP VIEW IF EXISTS contributions_new_mv'
    execute 'DROP TABLE IF EXISTS contributions_new'

    execute <<~SQL
      CREATE TABLE contributions_new
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        path String CODEC(ZSTD(3)),
        author_id Int64 CODEC(DoubleDelta, ZSTD),
        target_type LowCardinality(String) DEFAULT '',
        action Int16 DEFAULT 0,
        created_at DateTime64(6, 'UTC') DEFAULT now64(),
        updated_at DateTime64(6, 'UTC') DEFAULT now64(),
        version DateTime64(6, 'UTC') DEFAULT now() CODEC(ZSTD(1)),
        deleted Bool DEFAULT FALSE CODEC(ZSTD(1))
      )
      ENGINE = ReplacingMergeTree(version, deleted)
      ORDER BY (path, created_at, author_id, id)
      PARTITION BY toYYYYMM(created_at)
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW contributions_new_mv
      TO contributions_new
      AS
      WITH
        base AS (SELECT * FROM siphon_events
        WHERE
          (
            (
            action IN (5, 6) AND target_type = ''
            )
            OR
            (
               action IN (1, 3, 7, 12) AND
               target_type IN ('MergeRequest', 'Issue', 'WorkItem')
            )
          )
        )
      SELECT
        base.id AS id,
        base.path AS path,
        base.author_id AS author_id,
        base.target_type AS target_type,
        base.action AS action,
        base.created_at AS created_at,
        base.updated_at AS updated_at,
        base._siphon_replicated_at AS version,
        base._siphon_deleted AS deleted
      FROM base
    SQL
  end
end

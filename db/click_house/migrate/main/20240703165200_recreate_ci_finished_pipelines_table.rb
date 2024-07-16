# frozen_string_literal: true

class RecreateCiFinishedPipelinesTable < ClickHouse::Migration
  def up
    execute <<~SQL
      DROP TABLE IF EXISTS ci_finished_pipelines
    SQL

    execute <<~SQL
      CREATE TABLE ci_finished_pipelines
      (
        `id` UInt64 DEFAULT 0,
        `path` String DEFAULT '0/',
        `committed_at` DateTime64(6, 'UTC') DEFAULT 0,
        `created_at` DateTime64(6, 'UTC') DEFAULT 0,
        `started_at` DateTime64(6, 'UTC') DEFAULT 0,
        `finished_at` DateTime64(6, 'UTC') DEFAULT 0,
        `duration` UInt64 DEFAULT 0,
        `date` Date32 MATERIALIZED toStartOfMonth(finished_at),
        `status` LowCardinality(String) DEFAULT '',
        `source` LowCardinality(String) DEFAULT '',
        `ref` String DEFAULT ''
      )
      ENGINE = ReplacingMergeTree
      PARTITION BY toYear(finished_at)
      ORDER BY (id)
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS ci_finished_pipelines
    SQL

    execute <<~SQL
      CREATE TABLE ci_finished_pipelines
      (
        `id` UInt64 DEFAULT 0,
        `project_id` UInt64 DEFAULT 0,
        `committed_at` DateTime64(6, 'UTC') DEFAULT 0,
        `created_at` DateTime64(6, 'UTC') DEFAULT 0,
        `started_at` DateTime64(6, 'UTC') DEFAULT 0,
        `finished_at` DateTime64(6, 'UTC') DEFAULT 0,
        `duration` Int64,
        `date` Date32 MATERIALIZED toStartOfMonth(finished_at),
        `status` LowCardinality(String) DEFAULT '',
        `source` LowCardinality(String) DEFAULT '',
        `ref` String DEFAULT ''
      )
      ENGINE = ReplacingMergeTree
      PARTITION BY toYear(finished_at)
      ORDER BY (id)
    SQL
  end
end

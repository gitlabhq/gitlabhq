# frozen_string_literal: true

class CreateCiFinishedBuilds < ClickHouse::Migration
  def up
    execute <<~SQL
      -- source table for CI analytics, almost useless on it's own, but it's a basis for creating materialized views
      CREATE TABLE IF NOT EXISTS ci_finished_builds
      (
        id UInt64 DEFAULT 0,
        project_id UInt64 DEFAULT 0,
        pipeline_id UInt64 DEFAULT 0,
        status LowCardinality(String) DEFAULT '',

        --- Fields to calculate timings
        created_at DateTime64(6, 'UTC') DEFAULT now(),
        queued_at DateTime64(6, 'UTC') DEFAULT now(),
        finished_at DateTime64(6, 'UTC') DEFAULT now(),
        started_at DateTime64(6, 'UTC') DEFAULT now(),

        runner_id UInt64 DEFAULT 0,
        runner_manager_system_xid String DEFAULT '',

        --- Runner fields
        runner_run_untagged Boolean DEFAULT FALSE,
        runner_type UInt8 DEFAULT 0,
        runner_manager_version LowCardinality(String) DEFAULT '',
        runner_manager_revision LowCardinality(String) DEFAULT '',
        runner_manager_platform LowCardinality(String) DEFAULT '',
        runner_manager_architecture LowCardinality(String) DEFAULT '',

        --- Materialized columns
        duration Int64 MATERIALIZED age('ms', started_at, finished_at),
        queueing_duration Int64 MATERIALIZED age('ms', queued_at, started_at)
        --- This table is incomplete, we'll add more fields before starting the data migration
      )
      ENGINE = ReplacingMergeTree -- Using ReplacingMergeTree just in case we accidentally insert the same data twice
      ORDER BY (status, runner_type, project_id, finished_at, id)
      PARTITION BY toYear(finished_at)
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE ci_finished_builds
    SQL
  end
end

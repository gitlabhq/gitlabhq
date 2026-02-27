# frozen_string_literal: true

class AlterCiFinishedBuildsEngineWithVersion < ClickHouse::Migration
  def up
    create_tmp_table("ReplacingMergeTree(version, deleted)")
    attach_partitions
    exchange_tables
    drop_tmp_table
  end

  def down
    needs_rollback = engine_full.include?('version, deleted')

    drop_tmp_table

    return unless needs_rollback

    create_tmp_table("ReplacingMergeTree")
    attach_partitions
    exchange_tables
    drop_tmp_table
  end

  private

  def create_tmp_table(engine)
    settings = "index_granularity = 8192, use_async_block_ids_cache = true"
    settings += ", deduplicate_merge_projection_mode = 'rebuild'" if supports_deduplicate_merge_projection_mode?

    execute <<~SQL
        CREATE TABLE IF NOT EXISTS ci_finished_builds_tmp(
          `id` UInt64 DEFAULT 0,
          `project_id` UInt64 DEFAULT 0,
          `pipeline_id` UInt64 DEFAULT 0,
          `status` LowCardinality(String) DEFAULT '',
          `created_at` DateTime64(6, 'UTC') DEFAULT 0,
          `queued_at` DateTime64(6, 'UTC') DEFAULT 0,
          `finished_at` DateTime64(6, 'UTC') DEFAULT 0,
          `started_at` DateTime64(6, 'UTC') DEFAULT 0,
          `runner_id` UInt64 DEFAULT 0,
          `runner_manager_system_xid` String DEFAULT '',
          `runner_run_untagged` Bool DEFAULT false,
          `runner_type` UInt8 DEFAULT 0,
          `runner_manager_version` LowCardinality(String) DEFAULT '',
          `runner_manager_revision` LowCardinality(String) DEFAULT '',
          `runner_manager_platform` LowCardinality(String) DEFAULT '',
          `runner_manager_architecture` LowCardinality(String) DEFAULT '',
          `duration` Int64 MATERIALIZED if((started_at > 0) AND (finished_at > started_at), age('ms', started_at, finished_at), 0),
          `queueing_duration` Int64 MATERIALIZED if((queued_at > 0) AND (started_at > queued_at), age('ms', queued_at, started_at), 0),
          `root_namespace_id` UInt64 DEFAULT 0,
          `name` String DEFAULT '',
          `date` Date32 MATERIALIZED toStartOfMonth(finished_at),
          `runner_owner_namespace_id` UInt64 DEFAULT 0,
          `stage_id` UInt64 DEFAULT 0,
          `stage_name` String DEFAULT '',
          version DateTime64(6, 'UTC') DEFAULT now(),
          deleted Bool DEFAULT FALSE,
          PROJECTION build_stats_by_project_pipeline_name_stage_name
              (
              SELECT
                  project_id,
                  pipeline_id,
                  name,
                  stage_name,
                  countIf(status = 'success') AS success_count,
                  countIf(status = 'failed') AS failed_count,
                  countIf(status = 'canceled') AS canceled_count,
                  count() AS total_count,
                  sum(duration) AS sum_duration,
                  avg(duration) AS avg_duration,
                  quantile(0.95)(duration) AS p95_duration,
                  quantilesTDigest(0.5, 0.75, 0.9, 0.99)(duration) AS duration_quantiles
              GROUP BY
                  project_id,
                  pipeline_id,
                  name,
                  stage_name
              )
        )
          ENGINE = #{engine}
              PARTITION BY toYear(finished_at)
              ORDER BY (status, runner_type, project_id, finished_at, id)
              SETTINGS #{settings};
    SQL
  end

  def exchange_tables
    safe_table_swap('ci_finished_builds', 'ci_finished_builds_tmp', '_old')
  end

  def drop_tmp_table
    execute 'DROP TABLE IF EXISTS ci_finished_builds_tmp SETTINGS max_table_size_to_drop = 0'
  end

  def attach_partitions
    fetch_partitions.each do |partition|
      execute("ALTER TABLE ci_finished_builds_tmp ATTACH PARTITION #{partition} FROM ci_finished_builds")
    end
  end

  def fetch_partitions
    partitions_query = <<~SQL
      SELECT _partition_id AS partition
      FROM ci_finished_builds
      GROUP BY partition
    SQL

    connection.select(partitions_query).pluck('partition').sort
  end

  def engine_full
    engine_query = <<~SQL
      SELECT engine_full FROM system.tables WHERE name = 'ci_finished_builds';
    SQL
    connection.select(engine_query).pick('engine_full')
  end

  def supports_deduplicate_merge_projection_mode?
    version_query = <<~SQL
      SELECT version() AS version;
    SQL
    version_string = connection.select(version_query).pick('version')

    return false unless version_string

    version_parts = version_string.split('.').first(3).map(&:to_i)
    major = version_parts[0]
    minor = version_parts[1]

    (major == 24 && minor >= 1) || major >= 25
  end
end

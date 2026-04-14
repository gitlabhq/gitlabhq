# frozen_string_literal: true

# After the table swap, the _new tables contain the old (pre-swap) data.
# This migration drops them to clean up.
# See https://gitlab.com/gitlab-org/gitlab/-/issues/586319
class DropCiFinishedPipelinesAggregationShadowTables < ClickHouse::Migration
  def up
    execute <<~SQL
      DROP TABLE IF EXISTS ci_finished_pipelines_daily_new
    SQL

    execute <<~SQL
      DROP TABLE IF EXISTS ci_finished_pipelines_hourly_new
    SQL
  end

  def down
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS ci_finished_pipelines_daily_new
      (
        `path` String DEFAULT '0/',
        `status` LowCardinality(String) DEFAULT '',
        `source` LowCardinality(String) DEFAULT '',
        `ref` String DEFAULT '',
        `started_at_bucket` DateTime64(6, 'UTC') DEFAULT now64(),
        `count_pipelines` AggregateFunction(count),
        `duration_quantile` AggregateFunction(quantile, UInt64),
        `name` String DEFAULT ''
      )
      ENGINE = AggregatingMergeTree()
      ORDER BY (started_at_bucket, path, status, source, ref)
    SQL

    execute <<~SQL
      CREATE TABLE IF NOT EXISTS ci_finished_pipelines_hourly_new
      (
        `path` String DEFAULT '0/',
        `status` LowCardinality(String) DEFAULT '',
        `source` LowCardinality(String) DEFAULT '',
        `ref` String DEFAULT '',
        `started_at_bucket` DateTime64(6, 'UTC') DEFAULT now64(),
        `count_pipelines` AggregateFunction(count),
        `duration_quantile` AggregateFunction(quantile, UInt64),
        `name` String DEFAULT ''
      )
      ENGINE = AggregatingMergeTree()
      ORDER BY (started_at_bucket, path, status, source, ref)
    SQL
  end
end

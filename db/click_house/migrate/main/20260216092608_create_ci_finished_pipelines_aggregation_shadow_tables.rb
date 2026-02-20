# frozen_string_literal: true

class CreateCiFinishedPipelinesAggregationShadowTables < ClickHouse::Migration
  COLUMNS = <<~SQL
    `path` String DEFAULT '0/',
    `status` LowCardinality(String) DEFAULT '',
    `source` LowCardinality(String) DEFAULT '',
    `ref` String DEFAULT '',
    `started_at_bucket` DateTime64(6, 'UTC') DEFAULT now64(),
    `count_pipelines` AggregateFunction(count),
    `duration_quantile` AggregateFunction(quantile, UInt64),
    `name` String DEFAULT ''
  SQL

  TABLE_OPTIONS = <<~SQL
    ENGINE = AggregatingMergeTree()
    ORDER BY (started_at_bucket, path, status, source, ref)
  SQL

  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS ci_finished_pipelines_daily_new
      (#{COLUMNS})
      #{TABLE_OPTIONS}
    SQL

    execute <<~SQL
      CREATE TABLE IF NOT EXISTS ci_finished_pipelines_hourly_new
      (#{COLUMNS})
      #{TABLE_OPTIONS}
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS ci_finished_pipelines_hourly_new
    SQL

    execute <<~SQL
      DROP TABLE IF EXISTS ci_finished_pipelines_daily_new
    SQL
  end
end

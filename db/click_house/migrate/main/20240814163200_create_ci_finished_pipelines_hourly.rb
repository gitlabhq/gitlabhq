# frozen_string_literal: true

class CreateCiFinishedPipelinesHourly < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS ci_finished_pipelines_hourly
      (
        `path` String DEFAULT '0/',

        `status` LowCardinality(String) DEFAULT '',
        `source` LowCardinality(String) DEFAULT '',
        `ref` String DEFAULT '',
        `started_at_bucket` DateTime64(6, 'UTC') DEFAULT now64(),

        count_pipelines AggregateFunction(count)
      )
      ENGINE = AggregatingMergeTree()
      ORDER BY (started_at_bucket, path, status, source, ref)
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS ci_finished_pipelines_hourly
    SQL
  end
end

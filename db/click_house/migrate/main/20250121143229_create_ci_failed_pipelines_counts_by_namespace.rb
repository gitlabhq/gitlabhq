# frozen_string_literal: true

class CreateCiFailedPipelinesCountsByNamespace < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS ci_failed_pipelines_counts_by_namespace
      (
        path String DEFAULT '0/',
        failed_date Date DEFAULT toDate(now64()),
        count UInt64 DEFAULT 0
      )
      ENGINE = SummingMergeTree()
      PARTITION BY toYear(failed_date)
      ORDER BY (path, failed_date)
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS ci_failed_pipelines_counts_by_namespace
    SQL
  end
end

# frozen_string_literal: true

class DropCiFailedPipelinesCountsByNamespaceTable < ClickHouse::Migration
  def up
    execute <<~SQL
      DROP VIEW IF EXISTS ci_failed_pipelines_counts_by_namespace_mv
    SQL

    execute <<~SQL
      DROP TABLE IF EXISTS ci_failed_pipelines_counts_by_namespace
    SQL
  end

  def down
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

    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS ci_failed_pipelines_counts_by_namespace_mv
      TO ci_failed_pipelines_counts_by_namespace
      AS
      SELECT
          path,
          toDate(finished_at) as failed_date,
          count() as count
      FROM ci_finished_pipelines
      WHERE status = 'failed'
      GROUP BY path, failed_date;
    SQL
  end
end

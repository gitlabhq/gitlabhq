# frozen_string_literal: true

class CreateCiFailedPipelinesCountsByNamespaceMv < ClickHouse::Migration
  def up
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

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS ci_failed_pipelines_counts_by_namespace_mv
    SQL
  end
end

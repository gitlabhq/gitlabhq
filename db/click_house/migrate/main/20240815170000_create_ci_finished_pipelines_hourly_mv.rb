# frozen_string_literal: true

class CreateCiFinishedPipelinesHourlyMv < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS ci_finished_pipelines_hourly_mv
      TO ci_finished_pipelines_hourly
      AS
      SELECT
        path,
        status,
        source,
        ref,
        toStartOfInterval(started_at, INTERVAL 1 hour) AS started_at_bucket,

        countState() AS count_pipelines
      FROM ci_finished_pipelines
      GROUP BY path, status, source, ref, started_at_bucket
    SQL
  end

  def down
    execute <<~SQL
      DROP VIEW ci_finished_pipelines_hourly_mv
    SQL
  end
end

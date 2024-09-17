# frozen_string_literal: true

class CreateCiFinishedPipelinesDailyMv < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE MATERIALIZED VIEW ci_finished_pipelines_daily_mv TO ci_finished_pipelines_daily
      AS SELECT
        path,
        status,
        source,
        ref,
        toStartOfInterval(started_at, INTERVAL 1 day) AS started_at_bucket,
        countState() AS count_pipelines,
        quantileState(duration) AS duration_quantile
      FROM ci_finished_pipelines
      GROUP BY path, status, source, ref, started_at_bucket
    SQL
  end

  def down
    execute <<~SQL
      DROP VIEW ci_finished_pipelines_daily_mv
    SQL
  end
end

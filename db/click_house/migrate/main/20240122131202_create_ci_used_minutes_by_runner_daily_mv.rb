# frozen_string_literal: true

class CreateCiUsedMinutesByRunnerDailyMv < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS ci_used_minutes_by_runner_daily_mv
      TO ci_used_minutes_by_runner_daily
      AS
      SELECT
        toStartOfInterval(finished_at, INTERVAL 1 day) AS finished_at_bucket,
        runner_type,
        status,
        runner_id,

        countState() AS count_builds,
        sumSimpleState(duration) AS total_duration
      FROM ci_finished_builds
      GROUP BY finished_at_bucket, runner_type, status, runner_id
    SQL
  end

  def down
    execute <<~SQL
      DROP VIEW IF EXISTS ci_used_minutes_by_runner_daily_mv
    SQL
  end
end

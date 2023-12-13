# frozen_string_literal: true

class CreateCiUsedMinutesMv < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS ci_used_minutes_mv
      TO ci_used_minutes
      AS
      SELECT
        project_id,
        status,
        runner_type,
        toStartOfInterval(finished_at, INTERVAL 1 day) AS finished_at_bucket,

        countState() AS count_builds,
        sumSimpleState(duration) AS total_duration
      FROM ci_finished_builds
      GROUP BY project_id, status, runner_type, finished_at_bucket
    SQL
  end

  def down
    execute <<~SQL
      DROP VIEW ci_used_minutes_mv
    SQL
  end
end

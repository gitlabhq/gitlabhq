# frozen_string_literal: true

class CreateCiFinishedBuildsAggregatedQueueingDelayPercentilesMv < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS ci_finished_builds_aggregated_queueing_delay_percentiles_mv
      TO ci_finished_builds_aggregated_queueing_delay_percentiles
      AS
      SELECT
        status,
        runner_type,
        toStartOfInterval(started_at, INTERVAL 5 minute) AS started_at_bucket,

        countState(*) as count_builds,
        quantileState(queueing_duration) AS queueing_duration_quantile
      FROM ci_finished_builds
      GROUP BY status, runner_type, started_at_bucket
    SQL
  end

  def down
    execute <<~SQL
      DROP VIEW ci_finished_builds_aggregated_queueing_delay_percentiles_mv
    SQL
  end
end

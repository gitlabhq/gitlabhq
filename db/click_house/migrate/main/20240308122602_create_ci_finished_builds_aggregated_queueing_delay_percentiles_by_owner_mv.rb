# frozen_string_literal: true

class CreateCiFinishedBuildsAggregatedQueueingDelayPercentilesByOwnerMv < ClickHouse::Migration
  VIEW_NAME = "ci_finished_builds_aggregated_queueing_delay_percentiles_by_owner_mv"

  def up
    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS #{VIEW_NAME}
      TO ci_finished_builds_aggregated_queueing_delay_percentiles_by_owner
      AS
      SELECT
        toStartOfInterval(started_at, INTERVAL 5 minute) AS started_at_bucket,
        status,
        runner_type,
        runner_owner_namespace_id,

        countState(*) as count_builds,
        quantileState(queueing_duration) AS queueing_duration_quantile
      FROM ci_finished_builds
      GROUP BY started_at_bucket, status, runner_type, runner_owner_namespace_id
    SQL
  end

  def down
    execute <<~SQL
      DROP VIEW #{VIEW_NAME}
    SQL
  end
end

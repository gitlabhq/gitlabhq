CREATE MATERIALIZED VIEW ci_finished_builds_aggregated_queueing_delay_percentiles_mv
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

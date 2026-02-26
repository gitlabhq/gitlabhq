# frozen_string_literal: true

class RecreateBuildStatsProjectionWithFinishedAt < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_builds
        ADD PROJECTION IF NOT EXISTS build_stats_by_project_pipeline_finished_at_name_stage_name
          (
          SELECT
              project_id,
              pipeline_id,
              finished_at,
              name,
              stage_name,
              countIf(status = 'success') AS success_count,
              countIf(status = 'failed') AS failed_count,
              countIf(status = 'canceled') AS canceled_count,
              count() AS total_count,
              sum(duration) AS sum_duration,
              avg(duration) AS avg_duration,
              quantile(0.95)(duration) AS p95_duration,
              quantilesTDigest(0.5, 0.75, 0.9, 0.99)(duration) AS duration_quantiles
          GROUP BY
              project_id,
              pipeline_id,
              finished_at,
              name,
              stage_name
          );
    SQL

    execute <<~SQL
      ALTER TABLE ci_finished_builds MATERIALIZE PROJECTION build_stats_by_project_pipeline_finished_at_name_stage_name;
    SQL

    execute <<~SQL
      ALTER TABLE ci_finished_builds
        DROP PROJECTION IF EXISTS build_stats_by_project_pipeline_name_stage_name
        SETTINGS mutations_sync = 0;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_builds
        ADD PROJECTION IF NOT EXISTS build_stats_by_project_pipeline_name_stage_name
          (
          SELECT
              project_id,
              pipeline_id,
              name,
              stage_name,
              countIf(status = 'success') AS success_count,
              countIf(status = 'failed') AS failed_count,
              countIf(status = 'canceled') AS canceled_count,
              count() AS total_count,
              sum(duration) AS sum_duration,
              avg(duration) AS avg_duration,
              quantile(0.95)(duration) AS p95_duration,
              quantilesTDigest(0.5, 0.75, 0.9, 0.99)(duration) AS duration_quantiles
          GROUP BY
              project_id,
              pipeline_id,
              name,
              stage_name
          );
    SQL

    execute <<~SQL
      ALTER TABLE ci_finished_builds MATERIALIZE PROJECTION build_stats_by_project_pipeline_name_stage_name;
    SQL

    execute <<~SQL
      ALTER TABLE ci_finished_builds
        DROP PROJECTION IF EXISTS build_stats_by_project_pipeline_finished_at_name_stage_name
        SETTINGS mutations_sync = 0;
    SQL
  end
end

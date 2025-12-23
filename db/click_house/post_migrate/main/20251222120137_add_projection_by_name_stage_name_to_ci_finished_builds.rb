# frozen_string_literal: true

class AddProjectionByNameStageNameToCiFinishedBuilds < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_builds ADD PROJECTION IF NOT EXISTS build_stats_by_project_pipeline_name_stage_name
          (
          SELECT
              project_id,
              pipeline_id,
              name,
              stage_name,
              countIf(status = 'success') as success_count,
              countIf(status = 'failed') as failed_count,
              countIf(status = 'canceled') as canceled_count,
              count() as total_count,
              sum(duration) as sum_duration,
              avg(duration) as avg_duration,
              quantile(0.95)(duration) as p95_duration,
              quantilesTDigest(0.5, 0.75, 0.9, 0.99)(duration) as duration_quantiles
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
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_builds DROP PROJECTION IF EXISTS build_stats_by_project_pipeline_name_stage_name
      SETTINGS mutations_sync = 0;
    SQL
  end
end

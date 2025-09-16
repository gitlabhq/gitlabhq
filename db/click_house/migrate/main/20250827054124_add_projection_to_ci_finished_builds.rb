# frozen_string_literal: true

class AddProjectionToCiFinishedBuilds < ClickHouse::Migration
  def up
    # To support projections on ReplacingMergeTree (required for ClickHouse < 25.6)
    # https://clickhouse.com/docs/operations/settings/merge-tree-settings#deduplicate_merge_projection_mode
    execute <<~SQL
      ALTER TABLE ci_finished_builds
      MODIFY SETTING deduplicate_merge_projection_mode = 'rebuild';
    SQL

    execute <<~SQL
      ALTER TABLE ci_finished_builds ADD PROJECTION IF NOT EXISTS build_stats_by_project_pipeline_name_stage
          (
          SELECT
              project_id,
              pipeline_id,
              name,
              stage_id,
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
              stage_id
          );
    SQL

    execute <<~SQL
      ALTER TABLE ci_finished_builds MATERIALIZE PROJECTION build_stats_by_project_pipeline_name_stage;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_builds DROP PROJECTION IF EXISTS build_stats_by_project_pipeline_name_stage
      SETTINGS mutations_sync = 0;
    SQL
  end
end

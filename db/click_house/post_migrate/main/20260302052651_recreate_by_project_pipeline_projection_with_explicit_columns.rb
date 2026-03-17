# frozen_string_literal: true

class RecreateByProjectPipelineProjectionWithExplicitColumns < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_builds
        DROP PROJECTION IF EXISTS by_project_pipeline_finished_at_name;
    SQL

    execute <<~SQL
      ALTER TABLE ci_finished_builds
        ADD PROJECTION IF NOT EXISTS by_project_pipeline_finished_at_name_v2
          (
          SELECT
              id,
              project_id,
              pipeline_id,
              status,
              created_at,
              finished_at,
              started_at,
              name,
              stage_name,
              version,
              deleted,
              group_name,
              namespace_path,
              duration,
              queueing_duration
          ORDER BY project_id, pipeline_id, finished_at, name, id, version
          );
    SQL

    execute <<~SQL
      ALTER TABLE ci_finished_builds MATERIALIZE PROJECTION by_project_pipeline_finished_at_name_v2;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_builds
        DROP PROJECTION IF EXISTS by_project_pipeline_finished_at_name_v2;
    SQL

    execute <<~SQL
      ALTER TABLE ci_finished_builds
        ADD PROJECTION IF NOT EXISTS by_project_pipeline_finished_at_name
          (
          SELECT *, duration, queueing_duration
          ORDER BY project_id, pipeline_id, finished_at, name, id, version
          );
    SQL

    execute <<~SQL
      ALTER TABLE ci_finished_builds MATERIALIZE PROJECTION by_project_pipeline_finished_at_name;
    SQL
  end
end

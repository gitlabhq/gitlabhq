# frozen_string_literal: true

class AddBuildsByProjectPipelineProjectionToCiFinishedBuilds < ClickHouse::Migration
  def up
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

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_builds DROP PROJECTION IF EXISTS by_project_pipeline_finished_at_name
      SETTINGS mutations_sync = 0;
    SQL
  end
end

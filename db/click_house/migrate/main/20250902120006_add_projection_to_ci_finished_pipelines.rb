# frozen_string_literal: true

class AddProjectionToCiFinishedPipelines < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_pipelines
      MODIFY SETTING deduplicate_merge_projection_mode = 'rebuild';
    SQL

    execute <<~SQL
    ALTER TABLE ci_finished_pipelines ADD PROJECTION IF NOT EXISTS by_path_source_ref_finished_at
        (SELECT * ORDER BY path, source, ref, finished_at, id);
    SQL

    execute <<~SQL
      ALTER TABLE ci_finished_pipelines MATERIALIZE PROJECTION by_path_source_ref_finished_at;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_pipelines DROP PROJECTION IF EXISTS by_path_source_ref_finished_at
      SETTINGS mutations_sync = 0;
    SQL
  end
end

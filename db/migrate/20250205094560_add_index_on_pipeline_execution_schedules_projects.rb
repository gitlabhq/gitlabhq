# frozen_string_literal: true

class AddIndexOnPipelineExecutionSchedulesProjects < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  TABLE_NAME = :security_pipeline_execution_project_schedules
  INDEX_NAME = 'idx_pipeline_execution_schedules_on_project_id'

  def up
    # rubocop:disable Migration/AddIndex -- table was truncated
    add_index(TABLE_NAME, :project_id, name: INDEX_NAME)
    # rubocop:enable Migration/AddIndex
  end

  def down
    remove_index(TABLE_NAME, name: INDEX_NAME) # rubocop:disable Migration/RemoveIndex -- table was truncated
  end
end

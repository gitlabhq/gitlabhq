# frozen_string_literal: true

class IndexCiPipelineScheduleVariablesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_pipeline_schedule_variables_on_project_id'

  def up
    add_concurrent_index :ci_pipeline_schedule_variables, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_pipeline_schedule_variables, INDEX_NAME
  end
end

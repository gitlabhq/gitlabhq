# frozen_string_literal: true

class ScheduleIndexForPCiPipelineVariablesOnProjectId < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.1'

  TABLE_NAME = :p_ci_pipeline_variables
  INDEX_NAME = :index_p_ci_pipeline_variables_on_project_id
  COLUMN_NAME = :project_id

  def up
    prepare_partitioned_async_index(TABLE_NAME, COLUMN_NAME, name: INDEX_NAME)
  end

  def down
    unprepare_partitioned_async_index(TABLE_NAME, COLUMN_NAME, name: INDEX_NAME)
  end
end

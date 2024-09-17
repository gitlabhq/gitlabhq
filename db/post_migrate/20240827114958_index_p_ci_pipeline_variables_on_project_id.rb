# frozen_string_literal: true

class IndexPCiPipelineVariablesOnProjectId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.4'

  TABLE_NAME = :p_ci_pipeline_variables
  INDEX_NAME = :index_p_ci_pipeline_variables_on_project_id

  def up
    prepare_partitioned_async_index(TABLE_NAME, :project_id, name: INDEX_NAME)
  end

  def down
    unprepare_partitioned_async_index(TABLE_NAME, :project_id, name: INDEX_NAME)
  end
end

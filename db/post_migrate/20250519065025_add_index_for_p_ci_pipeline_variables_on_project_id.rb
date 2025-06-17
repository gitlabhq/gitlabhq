# frozen_string_literal: true

class AddIndexForPCiPipelineVariablesOnProjectId < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.1'

  TABLE_NAME = :p_ci_pipeline_variables
  INDEX_NAME = :index_p_ci_pipeline_variables_on_project_id
  COLUMN_NAME = :project_id

  def up
    add_concurrent_partitioned_index(TABLE_NAME, COLUMN_NAME, name: INDEX_NAME)
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end

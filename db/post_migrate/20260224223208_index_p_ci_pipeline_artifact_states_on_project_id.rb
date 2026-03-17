# frozen_string_literal: true

class IndexPCiPipelineArtifactStatesOnProjectId < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.10'
  disable_ddl_transaction!

  INDEX_NAME = 'index_p_ci_pipeline_artifact_states_on_project_id'

  def up
    add_concurrent_partitioned_index :p_ci_pipeline_artifact_states, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_partitioned_index_by_name :p_ci_pipeline_artifact_states, INDEX_NAME
  end
end

# frozen_string_literal: true

class AddUniqueConstraintPartitionIdToCiPipelineArtifacts < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.5'

  def up
    add_concurrent_index :ci_pipeline_artifacts,
      [:id, :partition_id],
      unique: true,
      name: 'index_ci_pipeline_artifacts_on_id_and_partition_id'
  end

  def down
    remove_concurrent_index_by_name :ci_pipeline_artifacts, 'index_ci_pipeline_artifacts_on_id_and_partition_id'
  end
end

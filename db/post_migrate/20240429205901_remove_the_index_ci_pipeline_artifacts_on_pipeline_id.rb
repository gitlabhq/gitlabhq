# frozen_string_literal: true

class RemoveTheIndexCiPipelineArtifactsOnPipelineId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.0'
  INDEX_NAME = 'index_ci_pipeline_artifacts_on_pipeline_id'

  def up
    remove_concurrent_index_by_name :ci_pipeline_artifacts, name: INDEX_NAME
  end

  def down
    add_concurrent_index :ci_pipeline_artifacts, :pipeline_id, name: INDEX_NAME
  end
end

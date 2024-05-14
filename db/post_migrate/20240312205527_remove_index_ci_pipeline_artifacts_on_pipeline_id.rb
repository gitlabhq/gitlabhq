# frozen_string_literal: true

class RemoveIndexCiPipelineArtifactsOnPipelineId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.11'

  def up
    prepare_async_index_removal :ci_pipeline_artifacts, :pipeline_id, name: 'index_ci_pipeline_artifacts_on_pipeline_id'
  end

  def down
    unprepare_async_index :ci_pipeline_artifacts, :pipeline_id, name: 'index_ci_pipeline_artifacts_on_pipeline_id'
  end
end

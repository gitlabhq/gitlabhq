# frozen_string_literal: true

class AddPCiPipelineArtifactStatesProjectIdTrigger < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def up
    install_sharding_key_assignment_trigger(
      table: :p_ci_pipeline_artifact_states,
      sharding_key: :project_id,
      parent_table: :ci_pipeline_artifacts,
      parent_sharding_key: :project_id,
      foreign_key: :pipeline_artifact_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :p_ci_pipeline_artifact_states,
      sharding_key: :project_id,
      parent_table: :ci_pipeline_artifacts,
      parent_sharding_key: :project_id,
      foreign_key: :pipeline_artifact_id
    )
  end
end

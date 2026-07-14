# frozen_string_literal: true

class AddNotNullConstraintToPCiPipelineArtifactStatesProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.2'

  def up
    add_not_null_constraint :p_ci_pipeline_artifact_states, :project_id
  end

  def down
    remove_not_null_constraint :p_ci_pipeline_artifact_states, :project_id
  end
end

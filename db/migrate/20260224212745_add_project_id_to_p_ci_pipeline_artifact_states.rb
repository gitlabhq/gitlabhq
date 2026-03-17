# frozen_string_literal: true

class AddProjectIdToPCiPipelineArtifactStates < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def change
    add_column :p_ci_pipeline_artifact_states, :project_id, :bigint
  end
end

# frozen_string_literal: true

class AddProjectIdToCiJobArtifactStates < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :ci_job_artifact_states, :project_id, :bigint
  end
end

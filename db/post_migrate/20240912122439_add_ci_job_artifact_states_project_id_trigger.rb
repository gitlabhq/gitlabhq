# frozen_string_literal: true

class AddCiJobArtifactStatesProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def up
    install_sharding_key_assignment_trigger(
      table: :ci_job_artifact_states,
      sharding_key: :project_id,
      parent_table: :p_ci_job_artifacts,
      parent_sharding_key: :project_id,
      foreign_key: :job_artifact_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :ci_job_artifact_states,
      sharding_key: :project_id,
      parent_table: :p_ci_job_artifacts,
      parent_sharding_key: :project_id,
      foreign_key: :job_artifact_id
    )
  end
end

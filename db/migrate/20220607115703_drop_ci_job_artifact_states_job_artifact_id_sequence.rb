# frozen_string_literal: true

class DropCiJobArtifactStatesJobArtifactIdSequence < Gitlab::Database::Migration[2.0]
  def up
    drop_sequence(:ci_job_artifact_states, :job_artifact_id, :ci_job_artifact_states_job_artifact_id_seq)
  end

  def down
    add_sequence(:ci_job_artifact_states, :job_artifact_id, :ci_job_artifact_states_job_artifact_id_seq, 1)
  end
end

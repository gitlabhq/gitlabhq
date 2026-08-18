# frozen_string_literal: true

class SyncRemoveIndexJobArtifactStatesOnVerificationState < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.2'

  INDEX_NAME = 'index_job_artifact_states_on_verification_state'

  def up
    remove_concurrent_index_by_name :ci_job_artifact_states, INDEX_NAME
  end

  def down
    add_concurrent_index :ci_job_artifact_states, :verification_state, name: INDEX_NAME
  end
end

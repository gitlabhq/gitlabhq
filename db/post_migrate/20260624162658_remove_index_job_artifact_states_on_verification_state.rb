# frozen_string_literal: true

class RemoveIndexJobArtifactStatesOnVerificationState < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  INDEX_NAME = 'index_job_artifact_states_on_verification_state'

  def up
    # Follow-up issue to remove index https://gitlab.com/gitlab-org/gitlab/-/work_items/473158
    prepare_async_index_removal :ci_job_artifact_states, :verification_state, name: INDEX_NAME
  end

  def down
    unprepare_async_index_by_name :ci_job_artifact_states, INDEX_NAME
  end
end

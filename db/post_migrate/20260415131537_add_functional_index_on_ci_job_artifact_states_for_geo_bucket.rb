# frozen_string_literal: true

class AddFunctionalIndexOnCiJobArtifactStatesForGeoBucket < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_job_artifact_states_on_bucket_number'
  BUCKET_COUNT = 100_000

  def up
    # rubocop:disable Migration/PreventIndexCreation -- https://gitlab.com/gitlab-org/database-team/team-tasks/-/work_items/614
    add_concurrent_index(
      :ci_job_artifact_states,
      "(job_artifact_id % #{BUCKET_COUNT})",
      name: INDEX_NAME
    )
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name(:ci_job_artifact_states, INDEX_NAME)
  end
end

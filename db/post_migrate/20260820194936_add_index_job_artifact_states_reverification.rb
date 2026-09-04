# frozen_string_literal: true

# See https://docs.gitlab.com/development/migration_style_guide/
# for more information on how to write migrations for GitLab.

class AddIndexJobArtifactStatesReverification < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  INDEX_NAME = 'index_job_artifact_states_reverification'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- Geo-only table, empty on GitLab.com. Exception issue: https://gitlab.com/gitlab-org/database-team/team-tasks/-/work_items/668
    add_concurrent_index(
      :ci_job_artifact_states,
      :verified_at,
      where: 'verification_state = 2',
      name: INDEX_NAME
    )
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name(:ci_job_artifact_states, INDEX_NAME)
  end
end

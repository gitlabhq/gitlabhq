# frozen_string_literal: true

class PrepareIndexCiJobArtifactStatesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_job_artifact_states_on_project_id'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
    prepare_async_index :ci_job_artifact_states, :project_id, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    unprepare_async_index :ci_job_artifact_states, INDEX_NAME
  end
end

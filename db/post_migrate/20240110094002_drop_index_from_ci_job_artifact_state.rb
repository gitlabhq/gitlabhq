# frozen_string_literal: true

class DropIndexFromCiJobArtifactState < Gitlab::Database::Migration[2.2]
  milestone '16.8'
  disable_ddl_transaction!

  INDEX_NAME = :index_ci_job_artifact_states_on_job_artifact_id
  TABLE_NAME = :ci_job_artifact_states

  def up
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, :job_artifact_id, name: INDEX_NAME)
  end
end

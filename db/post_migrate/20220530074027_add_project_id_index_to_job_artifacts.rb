# frozen_string_literal: true

class AddProjectIdIndexToJobArtifacts < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_ci_job_artifacts_on_project_id_and_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_job_artifacts, [:project_id, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_job_artifacts, INDEX_NAME
  end
end

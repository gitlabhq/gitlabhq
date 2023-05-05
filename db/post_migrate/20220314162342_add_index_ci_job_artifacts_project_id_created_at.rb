# frozen_string_literal: true

class AddIndexCiJobArtifactsProjectIdCreatedAt < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_ci_job_artifacts_on_id_project_id_and_created_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_job_artifacts, [:project_id, :created_at, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_job_artifacts, INDEX_NAME
  end
end

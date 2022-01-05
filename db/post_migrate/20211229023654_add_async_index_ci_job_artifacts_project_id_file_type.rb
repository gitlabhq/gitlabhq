# frozen_string_literal: true

class AddAsyncIndexCiJobArtifactsProjectIdFileType < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_job_artifacts_on_id_project_id_and_file_type'

  def up
    prepare_async_index :ci_job_artifacts, [:project_id, :file_type, :id], name: INDEX_NAME
  end

  def down
    unprepare_async_index_by_name :ci_job_artifacts, INDEX_NAME
  end
end

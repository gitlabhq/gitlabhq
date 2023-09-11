# frozen_string_literal: true

class AddCiJobArtifactsFileFinalPathIndex < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_job_artifacts_on_file_final_path'
  WHERE_CLAUSE = 'file_final_path IS NOT NULL'

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/423990
  def up
    prepare_async_index :ci_job_artifacts, :file_final_path, name: INDEX_NAME, where: WHERE_CLAUSE
  end

  def down
    unprepare_async_index :ci_job_artifacts, :file_final_path, name: INDEX_NAME, where: WHERE_CLAUSE
  end
end

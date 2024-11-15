# frozen_string_literal: true

class AddCiJobArtifactsFileFinalPathIndexSynchronously < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_job_artifacts_on_file_final_path'
  WHERE_CLAUSE = 'file_final_path IS NOT NULL'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
    add_concurrent_index :ci_job_artifacts, :file_final_path, name: INDEX_NAME, where: WHERE_CLAUSE
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name :ci_job_artifacts, INDEX_NAME
  end
end

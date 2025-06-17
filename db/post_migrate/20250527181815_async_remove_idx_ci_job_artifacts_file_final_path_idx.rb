# frozen_string_literal: true

class AsyncRemoveIdxCiJobArtifactsFileFinalPathIdx < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  TABLE_NAME = :p_ci_job_artifacts
  INDEX_NAME = :p_ci_job_artifacts_file_final_path_idx
  COLUMN = :file_final_path

  def up
    return unless Gitlab.com_except_jh?

    prepare_async_index_removal TABLE_NAME, COLUMN, name: INDEX_NAME
  end

  def down
    return unless Gitlab.com_except_jh?

    unprepare_async_index TABLE_NAME, COLUMN, name: INDEX_NAME
  end
end

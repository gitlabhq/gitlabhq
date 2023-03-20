# frozen_string_literal: true

class AddIndexOnExpiredUnlockedNonTraceJobArtifacts < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_job_artifacts_expire_at_unlocked_non_trace'

  def up
    add_concurrent_index :ci_job_artifacts, :expire_at,
      name: INDEX_NAME,
      where: 'locked = 0 AND file_type != 3 AND expire_at IS NOT NULL'
  end

  def down
    remove_concurrent_index_by_name :ci_job_artifacts, INDEX_NAME
  end
end

# frozen_string_literal: true

class AddAsyncIndexOnUnlockedNonTraceJobArtifactsExpireAt < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_ci_job_artifacts_expire_at_unlocked_non_trace'

  def up
    prepare_async_index :ci_job_artifacts, :expire_at,
      name: INDEX_NAME,
      where: 'locked = 0 AND file_type != 3 AND expire_at IS NOT NULL'
  end

  def down
    unprepare_async_index :ci_job_artifacts, :expire_at, name: INDEX_NAME
  end
end

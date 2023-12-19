# frozen_string_literal: true

class DropSyncIndexCiJobArtifactsOnExpireAtForRemoval < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_ci_job_artifacts_on_expire_at_for_removal'
  CONDITIONS = 'locked = 0 AND expire_at IS NOT NULL'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :ci_job_artifacts, name: INDEX_NAME
  end

  def down
    add_concurrent_index :ci_job_artifacts, [:expire_at], where: CONDITIONS, name: INDEX_NAME
  end
end

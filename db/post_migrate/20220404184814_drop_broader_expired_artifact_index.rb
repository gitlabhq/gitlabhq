# frozen_string_literal: true

class DropBroaderExpiredArtifactIndex < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  TABLE_NAME = 'ci_job_artifacts'
  INDEX_NAME = 'ci_job_artifacts_expire_at_unlocked_idx'

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, [:expire_at], where: 'locked = 0', name: INDEX_NAME
  end
end

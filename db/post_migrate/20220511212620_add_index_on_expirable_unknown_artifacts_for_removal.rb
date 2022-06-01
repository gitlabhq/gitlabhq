# frozen_string_literal: true

class AddIndexOnExpirableUnknownArtifactsForRemoval < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  TABLE_NAME = 'ci_job_artifacts'
  INDEX_NAME = 'tmp_index_ci_job_artifacts_on_expire_at_where_locked_unknown'
  CONDITIONS = 'locked = 2 AND expire_at IS NOT NULL'

  def up
    add_concurrent_index TABLE_NAME, [:expire_at, :job_id], name: INDEX_NAME, where: CONDITIONS
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end

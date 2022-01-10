# frozen_string_literal: true

class RemoveCiPipelinesLockVersionIndex < Gitlab::Database::Migration[1.0]
  TABLE = :ci_pipelines
  INDEX_NAME = 'tmp_index_ci_pipelines_lock_version'
  COLUMN = :id

  disable_ddl_transaction!

  def up
    remove_concurrent_index TABLE, COLUMN, where: "lock_version IS NULL", name: INDEX_NAME
  end

  def down
    add_concurrent_index TABLE, COLUMN, where: "lock_version IS NULL", name: INDEX_NAME
  end
end

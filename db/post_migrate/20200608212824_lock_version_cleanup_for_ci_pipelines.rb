# frozen_string_literal: true

class LockVersionCleanupForCiPipelines < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    validate_not_null_constraint :ci_pipelines, :lock_version
    remove_concurrent_index :ci_pipelines, :id, where: "lock_version IS NULL", name: "tmp_index_ci_pipelines_lock_version"
  end

  def down
    add_concurrent_index :ci_pipelines, :id, where: "lock_version IS NULL", name: "tmp_index_ci_pipelines_lock_version"
  end
end

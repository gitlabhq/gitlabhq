# frozen_string_literal: true

class RestorePreviousSchemaWithLockVersionIndices < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :issues, :lock_version, where: "lock_version IS NULL"
    add_concurrent_index :merge_requests, :lock_version, where: "lock_version IS NULL"
    add_concurrent_index :epics, :lock_version, where: "lock_version IS NULL"
    add_concurrent_index :ci_stages, :id, where: "lock_version IS NULL", name: "tmp_index_ci_stages_lock_version"
    add_concurrent_index :ci_builds, :id, where: "lock_version IS NULL", name: "tmp_index_ci_builds_lock_version"
    add_concurrent_index :ci_pipelines, :id, where: "lock_version IS NULL", name: "tmp_index_ci_pipelines_lock_version"
  end

  def down
    # no-op
  end
end

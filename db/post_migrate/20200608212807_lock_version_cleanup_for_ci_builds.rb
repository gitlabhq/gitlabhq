# frozen_string_literal: true

class LockVersionCleanupForCiBuilds < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    validate_not_null_constraint :ci_builds, :lock_version
    remove_concurrent_index :ci_builds, :id, where: "lock_version IS NULL", name: "tmp_index_ci_builds_lock_version"
  end

  def down
    add_concurrent_index :ci_builds, :id, where: "lock_version IS NULL", name: "tmp_index_ci_builds_lock_version"
  end
end

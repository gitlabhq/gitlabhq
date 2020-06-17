# frozen_string_literal: true

class LockVersionCleanupForCiStages < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    validate_not_null_constraint :ci_stages, :lock_version
    remove_concurrent_index :ci_stages, :id, where: "lock_version IS NULL", name: "tmp_index_ci_stages_lock_version"
  end

  def down
    add_concurrent_index :ci_stages, :id, where: "lock_version IS NULL", name: "tmp_index_ci_stages_lock_version"
  end
end

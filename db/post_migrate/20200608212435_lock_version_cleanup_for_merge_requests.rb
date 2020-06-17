# frozen_string_literal: true

class LockVersionCleanupForMergeRequests < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    validate_not_null_constraint :merge_requests, :lock_version
    remove_concurrent_index :merge_requests, :lock_version, where: "lock_version IS NULL"
  end

  def down
    add_concurrent_index :merge_requests, :lock_version, where: "lock_version IS NULL"
  end
end

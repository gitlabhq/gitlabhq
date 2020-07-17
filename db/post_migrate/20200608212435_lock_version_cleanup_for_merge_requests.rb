# frozen_string_literal: true

class LockVersionCleanupForMergeRequests < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    validate_not_null_constraint :merge_requests, :lock_version
    remove_concurrent_index_by_name :merge_requests, name: 'index_merge_requests_on_id'
  end

  def down
    add_concurrent_index :merge_requests, :id, where: "lock_version IS NULL", name: 'index_merge_requests_on_id'
  end
end

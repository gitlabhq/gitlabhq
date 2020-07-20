# frozen_string_literal: true

class SetProperLockVersionIndices < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index :epics, :lock_version, where: "lock_version IS NULL"
    remove_concurrent_index :merge_requests, :lock_version, where: "lock_version IS NULL"
    remove_concurrent_index :issues, :lock_version, where: "lock_version IS NULL"

    add_concurrent_index :epics, :id, where: "lock_version IS NULL", name: 'index_epics_on_id'
    add_concurrent_index :merge_requests, :id, where: "lock_version IS NULL", name: 'index_merge_requests_on_id'
    add_concurrent_index :issues, :id, where: "lock_version IS NULL", name: 'index_issues_on_id'
  end

  def down
    add_concurrent_index :epics, :lock_version, where: "lock_version IS NULL"
    add_concurrent_index :merge_requests, :lock_version, where: "lock_version IS NULL"
    add_concurrent_index :issues, :lock_version, where: "lock_version IS NULL"

    remove_concurrent_index_by_name :epics, name: 'index_epics_on_id'
    remove_concurrent_index_by_name :merge_requests, name: 'index_merge_requests_on_id'
    remove_concurrent_index_by_name :issues, name: 'index_issues_on_id'
  end
end

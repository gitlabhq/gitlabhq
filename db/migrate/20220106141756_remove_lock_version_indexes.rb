# frozen_string_literal: true

class RemoveLockVersionIndexes < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEXES = {
    issues: 'index_issues_on_lock_version',
    merge_requests: 'index_merge_requests_on_lock_version',
    epics: 'index_epics_on_lock_version'
  }

  def up
    INDEXES.each do |table, index_name|
      remove_concurrent_index_by_name table, index_name
    end
  end

  def down
    INDEXES.each do |table, index_name|
      add_concurrent_index table, :lock_version, where: "lock_version IS NULL", name: index_name
    end
  end
end

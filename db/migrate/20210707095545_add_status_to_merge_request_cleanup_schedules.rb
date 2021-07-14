# frozen_string_literal: true

class AddStatusToMergeRequestCleanupSchedules < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = 'index_merge_request_cleanup_schedules_on_status'

  disable_ddl_transaction!

  def up
    unless column_exists?(:merge_request_cleanup_schedules, :status)
      add_column(:merge_request_cleanup_schedules, :status, :integer, limit: 2, default: 0, null: false)
    end

    add_concurrent_index(:merge_request_cleanup_schedules, :status, name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:merge_request_cleanup_schedules, INDEX_NAME)

    if column_exists?(:merge_request_cleanup_schedules, :status)
      remove_column(:merge_request_cleanup_schedules, :status)
    end
  end
end

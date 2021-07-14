# frozen_string_literal: true

class UpdateMergeRequestCleanupSchedulesScheduledAtIndex < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = 'index_mr_cleanup_schedules_timestamps_status'
  OLD_INDEX_NAME = 'index_mr_cleanup_schedules_timestamps'

  disable_ddl_transaction!

  def up
    add_concurrent_index(:merge_request_cleanup_schedules, :scheduled_at, where: 'completed_at IS NULL AND status = 0', name: INDEX_NAME)
    remove_concurrent_index_by_name(:merge_request_cleanup_schedules, OLD_INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:merge_request_cleanup_schedules, INDEX_NAME)
    add_concurrent_index(:merge_request_cleanup_schedules, :scheduled_at, where: 'completed_at IS NULL', name: OLD_INDEX_NAME)
  end
end

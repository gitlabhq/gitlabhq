# frozen_string_literal: true

class CreateMergeRequestCleanupSchedules < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      create_table :merge_request_cleanup_schedules, id: false do |t|
        t.references :merge_request, primary_key: true, index: { unique: true }, null: false, foreign_key: { on_delete: :cascade }
        t.datetime_with_timezone :scheduled_at, null: false
        t.datetime_with_timezone :completed_at, null: true

        t.timestamps_with_timezone

        t.index :scheduled_at, where: 'completed_at IS NULL', name: 'index_mr_cleanup_schedules_timestamps'
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :merge_request_cleanup_schedules
    end
  end
end

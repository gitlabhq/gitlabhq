# frozen_string_literal: true

class AddFailedCountToMergeRequestCleanupSchedules < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def change
    add_column :merge_request_cleanup_schedules, :failed_count, :integer, default: 0, null: false
  end
end

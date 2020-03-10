# frozen_string_literal: true

class AddMergeRequestMetricsFirstReassignedAt < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :merge_request_metrics, :first_reassigned_at, :datetime_with_timezone
    end
  end

  def down
    with_lock_retries do
      remove_column :merge_request_metrics, :first_reassigned_at, :datetime_with_timezone
    end
  end
end

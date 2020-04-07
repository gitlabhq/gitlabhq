# frozen_string_literal: true

class AddLineMetricsToMrMetrics < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :merge_request_metrics, :added_lines, :integer
      add_column :merge_request_metrics, :removed_lines, :integer
    end
  end

  def down
    with_lock_retries do
      remove_column :merge_request_metrics, :added_lines, :integer
      remove_column :merge_request_metrics, :removed_lines, :integer
    end
  end
end

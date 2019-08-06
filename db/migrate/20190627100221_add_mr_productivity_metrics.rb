# frozen_string_literal: true

class AddMrProductivityMetrics < ActiveRecord::Migration[5.1]
  DOWNTIME = false

  def change
    add_column :merge_request_metrics, :first_comment_at, :datetime_with_timezone
    add_column :merge_request_metrics, :first_commit_at, :datetime_with_timezone
    add_column :merge_request_metrics, :last_commit_at, :datetime_with_timezone
    add_column :merge_request_metrics, :diff_size, :integer
    add_column :merge_request_metrics, :modified_paths_size, :integer
    add_column :merge_request_metrics, :commits_count, :integer
  end
end

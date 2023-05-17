# frozen_string_literal: true

class AddFirstContributionToMergeRequestMetrics < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :merge_request_metrics, :first_contribution, :boolean, default: false, null: false
  end
end

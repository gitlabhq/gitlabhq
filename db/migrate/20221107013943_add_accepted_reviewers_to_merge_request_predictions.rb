# frozen_string_literal: true

class AddAcceptedReviewersToMergeRequestPredictions < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :merge_request_predictions, :accepted_reviewers, :jsonb, null: false, default: {}
  end
end

# frozen_string_literal: true

class AddTimestampToMlCandidateMetrics < Gitlab::Database::Migration[2.0]
  def change
    add_column :ml_candidate_metrics, :tracked_at, :bigint
  end
end

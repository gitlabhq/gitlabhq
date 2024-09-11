# frozen_string_literal: true

class AddProjectIdToMlCandidateMetrics < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    add_column :ml_candidate_metrics, :project_id, :bigint
  end
end

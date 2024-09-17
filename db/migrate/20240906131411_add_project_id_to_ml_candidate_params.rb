# frozen_string_literal: true

class AddProjectIdToMlCandidateParams < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    add_column :ml_candidate_params, :project_id, :bigint
  end
end

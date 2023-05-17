# frozen_string_literal: true

class AddProjectIdToMlCandidates < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :ml_candidates, :project_id, :bigint, null: true
  end
end

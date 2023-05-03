# frozen_string_literal: true

class AddCiBuildIdToMlCandidate < Gitlab::Database::Migration[2.1]
  def change
    add_column :ml_candidates, :ci_build_id, :bigint, null: true
  end
end

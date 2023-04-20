# frozen_string_literal: true

class AddInternalIdToMlCandidates < Gitlab::Database::Migration[2.1]
  def change
    add_column :ml_candidates, :internal_id, :bigint, null: true
  end
end

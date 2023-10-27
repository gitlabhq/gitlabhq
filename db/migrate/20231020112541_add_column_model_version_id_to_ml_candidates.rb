# frozen_string_literal: true

class AddColumnModelVersionIdToMlCandidates < Gitlab::Database::Migration[2.1]
  def change
    add_column :ml_candidates, :model_version_id, :bigint, null: true
  end
end

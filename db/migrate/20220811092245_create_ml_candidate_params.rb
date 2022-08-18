# frozen_string_literal: true

class CreateMlCandidateParams < Gitlab::Database::Migration[2.0]
  def change
    create_table :ml_candidate_params do |t|
      t.timestamps_with_timezone null: false
      t.references :candidate,
                   foreign_key: { to_table: :ml_candidates },
                   index: true
      t.text :name, limit: 250, null: false
      t.text :value, limit: 250, null: false
    end
  end
end

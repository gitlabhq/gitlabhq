# frozen_string_literal: true

class CreateMlCandidateMetrics < Gitlab::Database::Migration[2.0]
  def change
    create_table :ml_candidate_metrics do |t|
      t.timestamps_with_timezone null: false
      t.references :candidate,
                   foreign_key: { to_table: :ml_candidates },
                   index: true
      t.float :value
      t.integer :step
      t.binary :is_nan
      t.text :name, limit: 250, null: false
    end
  end
end

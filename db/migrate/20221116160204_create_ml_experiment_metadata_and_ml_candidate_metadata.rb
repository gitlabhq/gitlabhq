# frozen_string_literal: true

class CreateMlExperimentMetadataAndMlCandidateMetadata < Gitlab::Database::Migration[2.0]
  def change
    create_table :ml_experiment_metadata do |t|
      t.timestamps_with_timezone null: false
      t.references :experiment,
                   foreign_key: { to_table: :ml_experiments, on_delete: :cascade },
                   index: false,
                   null: false
      t.text :name, limit: 255, null: false
      t.text :value, limit: 5000, null: false

      t.index [:experiment_id, :name], unique: true
    end

    create_table :ml_candidate_metadata do |t|
      t.timestamps_with_timezone null: false
      t.references :candidate,
                   foreign_key: { to_table: :ml_candidates, on_delete: :cascade },
                   index: false,
                   null: false
      t.text :name, limit: 255, null: false, index: true
      t.text :value, limit: 5000, null: false

      t.index [:candidate_id, :name], unique: true
    end
  end
end

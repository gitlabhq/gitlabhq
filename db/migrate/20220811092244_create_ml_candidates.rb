# frozen_string_literal: true

class CreateMlCandidates < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    create_table :ml_candidates do |t|
      t.timestamps_with_timezone null: false
      t.uuid :iid, null: false
      t.bigint :experiment_id, null: false
      t.references :user, foreign_key: true, index: true, on_delete: :nullify

      t.index [:experiment_id, :iid], unique: true
    end
  end
end

# frozen_string_literal: true

class AddMlCandidatesReferenceToExperiment < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ml_candidates, :ml_experiments, column: :experiment_id
  end

  def down
    with_lock_retries do
      remove_foreign_key :ml_candidates, column: :experiment_id
    end
  end
end

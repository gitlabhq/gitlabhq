# frozen_string_literal: true

class AddSequenceColumnToSprintsTable < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def up
    add_column :sprints, :sequence, :integer
    execute "ALTER TABLE sprints ADD CONSTRAINT sequence_is_unique_per_iterations_cadence_id UNIQUE (iterations_cadence_id, sequence) DEFERRABLE INITIALLY DEFERRED"
  end

  def down
    remove_column :sprints, :sequence
  end
end

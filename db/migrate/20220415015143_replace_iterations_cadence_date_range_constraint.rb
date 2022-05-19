# frozen_string_literal: true

class ReplaceIterationsCadenceDateRangeConstraint < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    execute <<~SQL
      ALTER TABLE sprints
        DROP CONSTRAINT IF EXISTS iteration_start_and_due_date_iterations_cadence_id_constraint;

      ALTER TABLE sprints
        ADD CONSTRAINT iteration_start_and_due_date_iterations_cadence_id_constraint
        EXCLUDE USING gist
        ( iterations_cadence_id WITH =,
          daterange(start_date, due_date, '[]') WITH &&
        )
        WHERE (group_id IS NOT NULL) DEFERRABLE INITIALLY DEFERRED;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE sprints
        DROP CONSTRAINT IF EXISTS iteration_start_and_due_date_iterations_cadence_id_constraint;

      ALTER TABLE sprints
        ADD CONSTRAINT iteration_start_and_due_date_iterations_cadence_id_constraint
        EXCLUDE USING gist
        ( iterations_cadence_id WITH =,
          daterange(start_date, due_date, '[]') WITH &&
        )
        WHERE (group_id IS NOT NULL);
    SQL
  end
end

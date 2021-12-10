# frozen_string_literal: true

class BackfillSequenceColumnForSprintsTable < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def up
    execute(
      <<-SQL
        UPDATE sprints
        SET sequence=t.row_number
        FROM (
          SELECT id, row_number() OVER (PARTITION BY iterations_cadence_id ORDER BY start_date)
          FROM sprints as s1
          WHERE s1.iterations_cadence_id IS NOT NULL
        ) as t
        WHERE t.id=sprints.id AND (sprints.sequence IS NULL OR sprints.sequence <> t.row_number)
      SQL
    )
  end

  def down
    # no-op
  end
end

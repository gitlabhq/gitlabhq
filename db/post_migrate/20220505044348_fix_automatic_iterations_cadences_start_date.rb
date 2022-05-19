# frozen_string_literal: true

class FixAutomaticIterationsCadencesStartDate < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute(<<~SQL)
      UPDATE iterations_cadences
      SET start_date=COALESCE(
        (
          SELECT start_date
          FROM sprints
          WHERE iterations_cadences.id=sprints.iterations_cadence_id
          ORDER BY sprints.start_date ASC
          LIMIT 1
        ),
        start_date
      )
      WHERE iterations_cadences.automatic=true;
    SQL
  end

  def down
    # no-op
    # The migration updates the records for the feature used behind a non-default feature flag.
    # The correct data can be computed with the records from 'sprints' table.
  end
end

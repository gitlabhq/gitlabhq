# frozen_string_literal: true

class UpdateStartDateForIterationsCadences < Gitlab::Database::Migration[2.0]
  include ::Gitlab::Database::DynamicModelHelpers

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  def up
    each_batch_range('iterations_cadences', connection: connection) do |min, max|
      execute(<<~SQL)
        UPDATE iterations_cadences
        SET start_date=ic.first_upcoming_iteration_start_date
        FROM (
          SELECT ic.id, sprints2.first_upcoming_iteration_start_date 
          FROM iterations_cadences as ic,
          LATERAL (
            -- For each cadence, query for the due date of its current iteration
            SELECT due_date as current_iteration_due_date FROM sprints
            WHERE iterations_cadence_id=ic.id AND start_date <= current_date AND due_date >= current_date
            LIMIT 1
          ) as sprints1,
          LATERAL (
            -- For each cadence, query for the start date of the first upcoming iteration (i.e, it starts after the current iteration)
            SELECT start_date as first_upcoming_iteration_start_date FROM sprints
            WHERE iterations_cadence_id=ic.id AND start_date > sprints1.current_iteration_due_date
            ORDER BY start_date ASC LIMIT 1
          ) as sprints2
          WHERE ic.automatic=true AND ic.id BETWEEN #{min} AND #{max}
        ) as ic
        WHERE iterations_cadences.id=ic.id;
      SQL
    end
  end

  def down
    each_batch_range('iterations_cadences', connection: connection) do |min, max|
      execute(<<~SQL)
        UPDATE iterations_cadences
        SET start_date=ic.first_iteration_start_date
        FROM (
          SELECT ic.id, sprints.start_date as first_iteration_start_date
          FROM iterations_cadences as ic,
            LATERAL (
              SELECT start_date FROM sprints WHERE iterations_cadence_id=ic.id ORDER BY start_date ASC LIMIT 1
            ) as sprints
          WHERE ic.automatic=true AND ic.id BETWEEN #{min} AND #{max}
        ) as ic
        WHERE iterations_cadences.id=ic.id;
      SQL
    end
  end
end

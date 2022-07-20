# frozen_string_literal: true

class UpdateLastRunDateForIterationsCadences < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute <<~SQL
      UPDATE iterations_cadences SET last_run_date=CURRENT_DATE WHERE automatic=true;
    SQL
  end

  def down
    # no op
    # 'last_run_date' stores the date on which the cadence record should be
    # updated using `CreateIterationsInAdvance` service that is idempotent
    # and the column is only useful for optimizing when to run the service
    # ('last_run_date' is also a misnomer as it can be better-named 'next_run_date'.)
  end
end

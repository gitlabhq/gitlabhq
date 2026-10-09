# frozen_string_literal: true

class AddStartedHourRunnerIdProjectionToSiphonPCiBuilds < ClickHouse::Migration
  # Columns are explicit: `SELECT *` breaks projection rebuilds on later column adds (!225458).
  # Readers must also filter on toStartOfHour(started_at): a bare started_at predicate binds to
  # the later started_at key column, so the hour prefix is never derived and nothing prunes.
  def up
    execute <<~SQL
      ALTER TABLE siphon_p_ci_builds
        ADD PROJECTION IF NOT EXISTS by_started_hour_runner_id
        (
          SELECT
            id,
            partition_id,
            started_at,
            queued_at,
            runner_id,
            status,
            type,
            _siphon_replicated_at,
            _siphon_deleted
          ORDER BY
            toStartOfHour(started_at),
            runner_id,
            started_at,
            id,
            partition_id
        )
    SQL

    execute <<~SQL
      ALTER TABLE siphon_p_ci_builds MATERIALIZE PROJECTION by_started_hour_runner_id
      SETTINGS mutations_sync = 0
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_p_ci_builds DROP PROJECTION IF EXISTS by_started_hour_runner_id
      SETTINGS mutations_sync = 0
    SQL
  end
end

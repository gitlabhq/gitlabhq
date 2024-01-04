# frozen_string_literal: true

class ModifyCiFinishedBuildsQueueingDurationCalculation < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_builds
        MODIFY COLUMN queueing_duration Int64 MATERIALIZED if(queued_at > 0 AND started_at > queued_at, age('ms', queued_at, started_at), 0)
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_builds
        MODIFY COLUMN queueing_duration Int64 MATERIALIZED age('ms', queued_at, started_at)
    SQL
  end
end

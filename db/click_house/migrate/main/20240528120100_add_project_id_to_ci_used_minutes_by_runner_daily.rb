# frozen_string_literal: true

class AddProjectIdToCiUsedMinutesByRunnerDaily < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_used_minutes_by_runner_daily
        ADD COLUMN IF NOT EXISTS project_id UInt64 DEFAULT 0
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_used_minutes_by_runner_daily
        DROP COLUMN IF EXISTS project_id
    SQL
  end
end

# frozen_string_literal: true

class ModifyCiFinishedBuildsDurationCalculation < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_builds
        MODIFY COLUMN duration Int64 MATERIALIZED if(started_at > 0 AND finished_at > started_at, age('ms', started_at, finished_at), 0)
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_builds
        MODIFY COLUMN duration Int64 MATERIALIZED age('ms', started_at, finished_at)
    SQL
  end
end

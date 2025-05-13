# frozen_string_literal: true

class AddStageIdToCiFinishedBuilds < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_builds
        ADD COLUMN IF NOT EXISTS stage_id UInt64 DEFAULT 0
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_builds
        DROP COLUMN IF EXISTS stage_id
    SQL
  end
end

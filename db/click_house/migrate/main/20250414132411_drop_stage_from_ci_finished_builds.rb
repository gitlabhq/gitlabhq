# frozen_string_literal: true

class DropStageFromCiFinishedBuilds < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_builds
        DROP COLUMN IF EXISTS stage
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_builds
        ADD COLUMN IF NOT EXISTS stage String DEFAULT ''
    SQL
  end
end

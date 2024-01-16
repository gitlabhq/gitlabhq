# frozen_string_literal: true

class AddNameToCiFinishedBuilds < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_builds
        ADD COLUMN IF NOT EXISTS name String DEFAULT ''
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_builds
        DROP COLUMN IF EXISTS name
    SQL
  end
end

# frozen_string_literal: true

class AddDateToCiFinishedBuilds < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_builds
        ADD COLUMN IF NOT EXISTS date Date32 MATERIALIZED toStartOfMonth(finished_at)
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_builds
        DROP COLUMN IF EXISTS date
    SQL
  end
end

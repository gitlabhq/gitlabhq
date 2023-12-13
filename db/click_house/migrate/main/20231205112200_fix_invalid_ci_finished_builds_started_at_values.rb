# frozen_string_literal: true

class FixInvalidCiFinishedBuildsStartedAtValues < ClickHouse::Migration
  def up
    # Fix existing records to have the new default
    execute <<~SQL
      ALTER TABLE ci_finished_builds UPDATE started_at = finished_at WHERE started_at > finished_at
    SQL
  end

  def down
    # no-op as there is no way to retrieve old data
  end
end

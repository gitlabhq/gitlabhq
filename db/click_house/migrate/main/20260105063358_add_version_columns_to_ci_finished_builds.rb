# frozen_string_literal: true

class AddVersionColumnsToCiFinishedBuilds < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_builds
      ADD COLUMN IF NOT EXISTS version DateTime64(6, 'UTC') DEFAULT now(),
      ADD COLUMN IF NOT EXISTS deleted Bool DEFAULT false;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_builds
      DROP COLUMN IF EXISTS version,
      DROP COLUMN IF EXISTS deleted
    SQL
  end
end

# frozen_string_literal: true

class AddStageNameToCiFinishedBuilds < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_builds
      ADD COLUMN IF NOT EXISTS `stage_name` String DEFAULT ''
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_builds
      DROP COLUMN IF EXISTS `stage_name`
    SQL
  end
end

# frozen_string_literal: true

class AddGroupNameToCiFinishedBuilds < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_builds
      ADD COLUMN IF NOT EXISTS `group_name` String DEFAULT ''
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_builds
      DROP COLUMN IF EXISTS `group_name`
    SQL
  end
end

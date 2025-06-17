# frozen_string_literal: true

class AddNameToCiFinishedPipelines < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_pipelines
      ADD COLUMN IF NOT EXISTS `name` String DEFAULT ''
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_pipelines
      DROP COLUMN IF EXISTS `name`
    SQL
  end
end

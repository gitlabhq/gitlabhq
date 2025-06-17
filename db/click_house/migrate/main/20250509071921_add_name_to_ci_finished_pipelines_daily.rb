# frozen_string_literal: true

class AddNameToCiFinishedPipelinesDaily < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_pipelines_daily
      ADD COLUMN IF NOT EXISTS `name` String DEFAULT ''
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_pipelines_daily
      DROP COLUMN IF EXISTS `name`
    SQL
  end
end

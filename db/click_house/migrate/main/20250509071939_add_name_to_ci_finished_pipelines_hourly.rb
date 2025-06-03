# frozen_string_literal: true

class AddNameToCiFinishedPipelinesHourly < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_pipelines_hourly
      ADD COLUMN IF NOT EXISTS `name` String DEFAULT ''
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_pipelines_hourly
      DROP COLUMN IF EXISTS `name`
    SQL
  end
end

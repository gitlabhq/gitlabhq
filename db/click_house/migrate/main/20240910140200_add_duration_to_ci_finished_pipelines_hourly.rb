# frozen_string_literal: true

class AddDurationToCiFinishedPipelinesHourly < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_pipelines_hourly
        ADD COLUMN IF NOT EXISTS duration_quantile AggregateFunction(quantile, UInt64)
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_pipelines_hourly
        DROP COLUMN IF EXISTS duration_quantile
    SQL
  end
end

# frozen_string_literal: true

class RenameInstanceStatisticsMeasurements < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def up
    rename_table_safely(:analytics_instance_statistics_measurements, :analytics_usage_trends_measurements)
  end

  def down
    undo_rename_table_safely(:analytics_instance_statistics_measurements, :analytics_usage_trends_measurements)
  end
end

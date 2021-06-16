# frozen_string_literal: true

class RenameInstanceStatisticsMeasurements < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  def up
    rename_table_safely(:analytics_instance_statistics_measurements, :analytics_usage_trends_measurements)
  end

  def down
    undo_rename_table_safely(:analytics_instance_statistics_measurements, :analytics_usage_trends_measurements)
  end
end

# frozen_string_literal: true

class FinalizeRenameInstanceStatisticsMeasurements < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  def up
    finalize_table_rename(:analytics_instance_statistics_measurements, :analytics_usage_trends_measurements)
  end

  def down
    undo_finalize_table_rename(:analytics_instance_statistics_measurements, :analytics_usage_trends_measurements)
  end
end

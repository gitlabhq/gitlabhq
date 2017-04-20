class MoveTriggerSchedulesToPipelineSchedules < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    move_data("ci_trigger_schedules", "ci_pipeline_schedules")
  end

  def down
    move_data("ci_pipeline_schedules", "ci_trigger_schedules")
  end

  private

  def move_data(from, to)
    execute("INSERT INTO #{to} SELECT * FROM #{from}")
  end
end

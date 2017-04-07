class AddActiveToCiTriggerSchedule < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_trigger_schedules, :active, :boolean
  end
end

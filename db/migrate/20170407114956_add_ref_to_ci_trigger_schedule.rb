class AddRefToCiTriggerSchedule < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_trigger_schedules, :ref, :string
  end
end

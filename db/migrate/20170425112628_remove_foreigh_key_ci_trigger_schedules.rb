class RemoveForeighKeyCiTriggerSchedules < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    remove_foreign_key :ci_trigger_schedules, column: :trigger_id
  end

  def down
    # no op, the foreign key should not have been here
  end
end

class RemoveForeighKeyCiTriggerSchedules < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    if fk_on_trigger_schedules?
      remove_foreign_key :ci_trigger_schedules, column: :trigger_id
    end
  end

  def down
    # no op, the foreign key should not have been here
  end

  private

  # Not made more generic and lifted to the helpers as Rails 5 will provide
  # such an API
  def fk_on_trigger_schedules?
    connection.foreign_keys(:ci_trigger_schedules).include?("ci_triggers")
  end
end

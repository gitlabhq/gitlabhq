class AddTriggerIdForeignKey < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ci_trigger_schedules, :ci_triggers, column: :trigger_id, on_delete: :cascade
  end

  def down
    remove_foreign_key :ci_trigger_schedules, column: :trigger_id
  end
end

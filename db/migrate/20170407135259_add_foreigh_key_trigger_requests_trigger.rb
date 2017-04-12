class AddForeighKeyTriggerRequestsTrigger < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(:ci_trigger_requests, :ci_triggers, column: :trigger_id)
  end

  def down
    remove_foreign_key(:ci_trigger_requests, column: :trigger_id)
  end
end

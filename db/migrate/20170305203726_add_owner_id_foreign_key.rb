class AddOwnerIdForeignKey < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ci_triggers, :users, column: :owner_id, on_delete: :cascade
  end

  def down
    remove_foreign_key :ci_triggers, column: :owner_id
  end
end

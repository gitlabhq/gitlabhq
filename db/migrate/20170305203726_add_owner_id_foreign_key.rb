class AddOwnerIdForeignKey < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_concurrent_foreign_key :ci_triggers, :users, column: :owner_id, on_delete: :cascade
  end
end

class AddOwnerIdToTriggers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_triggers, :owner_id, :integer
    add_foreign_key :ci_triggers, :users, column: :owner_id, on_delete: :nullify
  end
end

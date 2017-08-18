class AddGroupMilestoneIdIndexes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    return if index_exists?(:milestones, :group_id)

    add_concurrent_foreign_key :milestones, :namespaces, column: :group_id, on_delete: :cascade

    add_concurrent_index :milestones, :group_id
  end

  def down
    remove_foreign_key :milestones, column: :group_id

    remove_concurrent_index :milestones, :group_id
  end
end

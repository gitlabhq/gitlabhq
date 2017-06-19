class AddGroupMilestoneIdIndexes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_foreign_key :issues, :namespaces, column: :group_milestone_id
    add_foreign_key :merge_requests, :namespaces, column: :group_milestone_id

    add_concurrent_index :issues, :group_milestone_id
    add_concurrent_index :merge_requests, :group_milestone_id
  end

  def down
    remove_foreign_key :issues, column: :group_milestone_id
    remove_foreign_key :merge_requests, column: :group_milestone_id

    remove_concurrent_index :issues, :group_milestone_id
    remove_concurrent_index :merge_requests, :group_milestone_id
  end
end

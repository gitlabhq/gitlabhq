class AddCiRunnerGroups < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :ci_runner_groups do |t|
      t.integer :runner_id
      t.integer :group_id
    end

    add_concurrent_index :ci_runner_groups, :group_id
    add_concurrent_index :ci_runner_groups, [:runner_id, :group_id], unique: true
    add_concurrent_foreign_key :ci_runner_groups, :ci_runners, column: :runner_id, on_delete: :cascade
    add_concurrent_foreign_key :ci_runner_groups, :namespaces, column: :group_id, on_delete: :cascade
  end

  def down
    drop_table :ci_runner_groups
  end
end

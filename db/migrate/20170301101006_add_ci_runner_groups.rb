class AddCiRunnerGroups < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    create_table :ci_runner_groups do |t|
      t.integer :runner_id
      t.integer :group_id

      t.index [:runner_id, :group_id], unique: true
      t.index :group_id
      t.foreign_key :ci_runners, column: :runner_id, on_delete: :cascade
      t.foreign_key :namespaces, column: :group_id, on_delete: :cascade
    end
  end
end

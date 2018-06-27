class AddCiRunnerNamespaces < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :ci_runner_namespaces do |t|
      t.integer :runner_id
      t.integer :namespace_id

      t.index [:runner_id, :namespace_id], unique: true
      t.index :namespace_id
      t.foreign_key :ci_runners, column: :runner_id, on_delete: :cascade
      t.foreign_key :namespaces, column: :namespace_id, on_delete: :cascade
    end
  end
end

class AddCiRunnerBuilds < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :ci_runner_builds do |t|
      t.integer :runner_id
      t.integer :project_id
      t.integer :build_id
      t.timestamps
    end

    add_index :ci_runner_builds, :runner_id
    add_index :ci_runner_builds, :project_id
    add_index :ci_runner_builds, :build_id
    add_index :ci_runner_builds, [:runner_id, :project_id, :build_id], unique: true

    add_foreign_key :ci_runner_builds, :ci_runners, column: :runner_id, on_delete: :cascade
    add_foreign_key :ci_runner_builds, :ci_builds, column: :build_id, on_delete: :cascade
    add_foreign_key :ci_runner_builds, :projects, on_delete: :cascade
  end
end

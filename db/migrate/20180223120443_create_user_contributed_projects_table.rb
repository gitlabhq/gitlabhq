class CreateUserContributedProjectsTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :user_contributed_projects, id: false do |t|
      t.references :user, null: false
      t.references :project, null: false

      t.index [:user_id, :project_id], unique: true
    end

    add_concurrent_foreign_key :user_contributed_projects, :users, column: :user_id, on_delete: :cascade
    add_concurrent_foreign_key :user_contributed_projects, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    drop_table :user_contributed_projects
  end
end

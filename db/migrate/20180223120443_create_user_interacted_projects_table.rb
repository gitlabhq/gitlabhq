class CreateUserInteractedProjectsTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :user_interacted_projects, id: false do |t|
      t.references :user, null: false
      t.references :project, null: false
    end
  end

  def down
    drop_table :user_interacted_projects
  end
end

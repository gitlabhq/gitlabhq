class CreateUserInteractedProjectsTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INDEX_NAME = 'user_interacted_projects_non_unique_index'

  def up
    create_table :user_interacted_projects, id: false do |t|
      t.references :user, null: false
      t.references :project, null: false
    end

    add_index :user_interacted_projects, [:project_id, :user_id], name: INDEX_NAME
  end

  def down
    drop_table :user_interacted_projects
  end
end

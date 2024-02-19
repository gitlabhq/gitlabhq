# frozen_string_literal: true

class DropUserInteractedProjectsTable < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  disable_ddl_transaction!

  TABLE_NAME = 'user_interacted_projects'
  INDEX_NAME = 'index_user_interacted_projects_on_user_id'
  PRIMARY_KEY_CONSTRAINT = 'user_interacted_projects_pkey'

  def up
    drop_table :user_interacted_projects
  end

  def down
    unless table_exists?(:user_interacted_projects)
      create_table :user_interacted_projects, id: false do |t|
        t.integer :user_id, null: false
        t.integer :project_id, null: false
        t.index :user_id, name: INDEX_NAME
      end
    end

    execute "ALTER TABLE #{TABLE_NAME} ADD CONSTRAINT #{PRIMARY_KEY_CONSTRAINT} PRIMARY KEY (project_id, user_id)"
  end
end

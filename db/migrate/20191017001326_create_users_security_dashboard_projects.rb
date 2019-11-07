# frozen_string_literal: true

class CreateUsersSecurityDashboardProjects < ActiveRecord::Migration[5.2]
  DOWNTIME = false
  INDEX_NAME = 'users_security_dashboard_projects_unique_index'

  def change
    create_table :users_security_dashboard_projects, id: false do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :project, null: false, index: false, foreign_key: { on_delete: :cascade }
    end

    add_index :users_security_dashboard_projects, [:project_id, :user_id], name: INDEX_NAME, unique: true
  end
end

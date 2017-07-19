# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateProjectAccessRequests < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :project_access_requests, id: false do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.datetime_with_timezone :created_at, null: false
      t.index [:project_id, :user_id], unique: true
    end
  end
end

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateGroupAccessRequests < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :group_access_requests, id: false do |t|
      # Must add group_id foreign key manually in next migration so we can use a
      # custom table name (we wouldn't have to do this in Rails 5).
      t.integer :group_id, null: false
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.datetime_with_timezone :created_at, null: false
      t.index [:group_id, :user_id], unique: true
    end
  end
end

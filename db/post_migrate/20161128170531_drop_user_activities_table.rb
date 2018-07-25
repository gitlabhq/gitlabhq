# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.
class DropUserActivitiesTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # When using the methods "add_concurrent_index" or "add_column_with_default"
  # you must disable the use of transactions as these methods can not run in an
  # existing transaction. When using "add_concurrent_index" make sure that this
  # method is the _only_ method called in the migration, any other changes
  # should go in a separate migration. This ensures that upon failure _only_ the
  # index creation fails and can be retried or reverted easily.
  #
  # To disable transactions uncomment the following line and remove these
  # comments:
  # disable_ddl_transaction!

  def up
    drop_table :user_activities if table_exists?(:user_activities)
  end

  def down
    unless table_exists?(:user_activities)
      create_table "user_activities", force: :cascade do |t|
        t.integer "user_id"
        t.datetime "last_activity_at", null: false
      end

      add_index "user_activities", ["user_id"], name: "index_user_activities_on_user_id", unique: true, using: :btree
    end
  end
end

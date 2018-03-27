# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddForeignKeyForMembers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(:members,
                               :users,
                               column: :user_id)
  end

  def down
    remove_foreign_key(:members, column: :user_id)
  end
end

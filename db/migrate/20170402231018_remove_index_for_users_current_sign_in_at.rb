# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.
class RemoveIndexForUsersCurrentSignInAt < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index :users, :current_sign_in_at
  end

  def down
    add_concurrent_index :users, :current_sign_in_at
  end
end

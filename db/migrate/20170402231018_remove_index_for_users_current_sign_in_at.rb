# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

# rubocop:disable RemoveIndex
class RemoveIndexForUsersCurrentSignInAt < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    if index_exists? :users, :current_sign_in_at
      if Gitlab::Database.postgresql?
        execute 'DROP INDEX CONCURRENTLY index_users_on_current_sign_in_at;'
      else
        remove_concurrent_index :users, :current_sign_in_at
      end
    end
  end

  def down
    add_concurrent_index :users, :current_sign_in_at
  end
end

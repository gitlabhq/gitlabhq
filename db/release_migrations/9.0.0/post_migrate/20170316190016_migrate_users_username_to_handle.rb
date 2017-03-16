# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MigrateUsersUsernameToHandle < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    old_column = Arel::Table.new(:users)[:username]

    # This will set users.handle to users.username in batches.
    update_column_in_batches(:users, :handle, old_column)
  end

  def down
    old_column = Arel::Table.new(:users)[:handle]

    update_column_in_batches(:users, :username, old_column)
  end
end

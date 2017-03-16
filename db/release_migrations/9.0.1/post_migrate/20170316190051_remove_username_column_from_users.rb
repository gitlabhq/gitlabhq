# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveUsernameColumnFromUsers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_column :users, :username
  end

  def down
    add_column :users, :username, :string

    # Populate the column with data again so we can safely revert the migration
    # without losing any data.
    old_column = Arel::Table.new(:users)[:handle]

    update_column_in_batches(:users, :username, old_column)
  end
end

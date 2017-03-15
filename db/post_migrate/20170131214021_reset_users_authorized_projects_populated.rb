# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ResetUsersAuthorizedProjectsPopulated < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # This ensures we don't lock all users for the duration of the migration.
    update_column_in_batches(:users, :authorized_projects_populated, nil)
  end

  def down
    # noop
  end
end

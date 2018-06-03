# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndexForActiveUsers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:users, :state, name: 'index_users_on_state_and_internal_attrs', where: "ghost <> true AND support_bot <> true")
  end

  def down
    remove_concurrent_index(:users, name: :index_users_on_state_and_internal_attrs)
  end
end

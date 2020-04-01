# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddMigratingUserHighestRolesTableIndexToUsers < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_for_migrating_user_highest_roles_table'

  disable_ddl_transaction!

  def up
    add_concurrent_index :users,
                         :id,
                         where: "state = 'active' AND user_type IS NULL AND bot_type IS NULL AND ghost IS NOT TRUE",
                         name: INDEX_NAME
  end

  def down
    remove_concurrent_index :users, :id, name: INDEX_NAME
  end
end

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveUserAuthenticationToken < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_column :users, :authentication_token
  end

  def down
    add_column :users, :authentication_token, :string

    add_concurrent_index :users, :authentication_token, unique: true
  end
end

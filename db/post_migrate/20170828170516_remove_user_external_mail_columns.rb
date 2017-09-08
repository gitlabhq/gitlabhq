# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveUserExternalMailColumns < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    remove_column :users, :external_email, :boolean
  end

  def down
    add_column :users, :external_email, :boolean
  end
end

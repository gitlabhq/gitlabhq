# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddPrivateProfileToUsers < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :users, :private_profile, :boolean
  end
end

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddThemeIdToUsers < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :users, :theme_id, :integer, limit: 2
  end
end

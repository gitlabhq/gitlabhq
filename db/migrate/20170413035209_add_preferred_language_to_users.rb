# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddPreferredLanguageToUsers < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column :users, :preferred_language, :string
  end

  def down
    remove_column :users, :preferred_language
  end
end

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class FixEmailOptedInAtOnUsers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    remove_column :users, :email_opted_in_at
    add_column :users, :email_opted_in_at, :datetime, null: true
  end

  def down
    remove_column :users, :email_opted_in_at
    add_column :users, :email_opted_in_at, :datetime_with_timezone, null: true
  end
end

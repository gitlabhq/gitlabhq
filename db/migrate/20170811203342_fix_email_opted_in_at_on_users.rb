# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class FixEmailOptedInAtOnUsers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    # MySQL makes the first TIMESTAMP column in a table default to
    # CURRENT_TIMESTAMP and gives it a NOT NULL constraint
    # (https://bugs.mysql.com/bug.php?id=75098). This prevents this value from
    # ever being set to NULL. While it's possible to override MySQL's behavior
    # in the the migration by adding null: true to add_column, this does not do
    # the right thing when the database is initialized from scratch. Using the
    # DATETIME type avoids these pitfalls.
    remove_column :users, :email_opted_in_at
    add_column :users, :email_opted_in_at, :datetime, null: true # rubocop:disable Migration/Datetime
  end

  def down
    remove_column :users, :email_opted_in_at
    add_column :users, :email_opted_in_at, :datetime_with_timezone, null: true
  end
end

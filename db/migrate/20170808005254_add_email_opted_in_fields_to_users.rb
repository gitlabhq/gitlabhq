# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddEmailOptedInFieldsToUsers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :users, :email_opted_in, :boolean, null: true
    add_column :users, :email_opted_in_ip, :string, null: true
    add_column :users, :email_opted_in_source_id, :integer, null: true
    add_column :users, :email_opted_in_at, :datetime_with_timezone, null: true
  end
end

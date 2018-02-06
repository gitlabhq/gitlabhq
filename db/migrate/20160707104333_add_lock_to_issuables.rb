# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddLockToIssuables < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column :issues, :lock_version, :integer
    add_column :merge_requests, :lock_version, :integer
  end

  def down
    remove_column :issues, :lock_version
    remove_column :merge_requests, :lock_version
  end
end

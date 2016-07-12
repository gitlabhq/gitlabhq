# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddLockToIssuables < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  def up
    add_column_with_default :issues, :lock_version, :integer, default: 0
    add_column_with_default :merge_requests, :lock_version, :integer, default: 0
  end

  def down
    remove_column :issues, :lock_version
    remove_column :merge_requests, :lock_version
  end
end

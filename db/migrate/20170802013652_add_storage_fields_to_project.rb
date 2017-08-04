# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddStorageFieldsToProject < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    # rubocop:disable Migration/AddColumnWithDefaultToLargeTable
    add_column :projects, :storage_version, :integer, limit: 2
    add_concurrent_index :projects, :storage_version
  end

  def down
    remove_column :projects, :storage_version
  end
end

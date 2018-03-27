# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddStorageFieldsToProject < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column :projects, :storage_version, :integer, limit: 2
  end

  def down
    remove_column :projects, :storage_version
  end
end

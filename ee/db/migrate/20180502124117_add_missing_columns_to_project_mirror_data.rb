# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddMissingColumnsToProjectMirrorData < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :project_mirror_data, :last_update_at, :datetime_with_timezone unless column_exists?(:project_mirror_data, :last_update_at)
    add_column :project_mirror_data, :last_successful_update_at, :datetime_with_timezone unless column_exists?(:project_mirror_data, :last_successful_update_at)
  end

  def down
    remove_column :project_mirror_data, :last_update_at
    remove_column :project_mirror_data, :last_successful_update_at
  end
end

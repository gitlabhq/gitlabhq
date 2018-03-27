# rubocop:disable Migration/RemoveColumn
# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

# rubocop:disable Migration/UpdateLargeTable
class RemoveFeaturesEnabledFromProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = true
  DOWNTIME_REASON = "Removing fields from database requires downtine."

  def up
    remove_column :projects, :issues_enabled
    remove_column :projects, :merge_requests_enabled
    remove_column :projects, :builds_enabled
    remove_column :projects, :wiki_enabled
    remove_column :projects, :snippets_enabled
  end

  # Ugly SQL but the only way i found to make it work on both Postgres and Mysql
  # It will be slow but it is ok since it is a revert method
  def down
    add_column_with_default(:projects, :issues_enabled, :boolean, default: true, allow_null: false)
    add_column_with_default(:projects, :merge_requests_enabled, :boolean, default: true, allow_null: false)
    add_column_with_default(:projects, :builds_enabled, :boolean, default: true, allow_null: false)
    add_column_with_default(:projects, :wiki_enabled, :boolean, default: true, allow_null: false)
    add_column_with_default(:projects, :snippets_enabled, :boolean, default: true, allow_null: false)
  end
end

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

# rubocop:disable Migration/UpdateLargeTable
class AddPrintingMergeRequestLinkEnabledToProject < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    add_column_with_default(:projects, :printing_merge_request_link_enabled, :boolean, default: true)
  end

  def down
    remove_column(:projects, :printing_merge_request_link_enabled)
  end
end

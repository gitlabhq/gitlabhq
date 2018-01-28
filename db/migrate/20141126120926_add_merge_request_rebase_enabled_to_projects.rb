# rubocop:disable all
class AddMergeRequestRebaseEnabledToProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:projects, :merge_requests_rebase_enabled, :boolean, default: false)
  end

  def down
    remove_column(:projects, :merge_requests_rebase_enabled)
  end
end

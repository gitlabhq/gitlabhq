# rubocop:disable all
class AddFastForwardOptionToProject < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:projects, :merge_requests_ff_only_enabled, :boolean, default: false)
  end

  def down
    if column_exists?(:projects, :merge_requests_ff_only_enabled)
      remove_column(:projects, :merge_requests_ff_only_enabled)
    end
  end
end

# rubocop:disable all
class MakeSureFastForwardOptionExists < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # We had to fix the migration db/migrate/20150827121444_add_fast_forward_option_to_project.rb
    # And this is why it's possible that someone has ran the migrations but does
    # not have the merge_requests_ff_only_enabled column. This migration makes sure it will
    # be added
    unless column_exists?(:projects, :merge_requests_ff_only_enabled)
      add_column_with_default(:projects, :merge_requests_ff_only_enabled, :boolean, default: false)
    end
  end

  def down
    if column_exists?(:projects, :merge_requests_ff_only_enabled)
      remove_column(:projects, :merge_requests_ff_only_enabled)
    end
  end
end

# rubocop:disable all
class AddFastForwardOptionToProject < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # We put condition here because of a mistake we made a couple of years ago
    # see https://gitlab.com/gitlab-org/gitlab-ce/issues/39382#note_45716103
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

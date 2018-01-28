# rubocop:disable Migration/UpdateLargeTable
class AddOnlyAllowMergeIfBuildSucceedsToProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  def up
    add_column_with_default(:projects,
                            :only_allow_merge_if_build_succeeds,
                            :boolean,
                            default: false)
  end

  def down
    remove_column(:projects, :only_allow_merge_if_build_succeeds)
  end
end

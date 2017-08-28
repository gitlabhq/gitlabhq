# rubocop:disable Migration/AddColumnWithDefaultToLargeTable
class CollapseOutdatedDiffComments < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    add_column_with_default(:projects,
                            :collapse_outdated_diff_comments,
                            :boolean,
                            default: false)
  end

  def down
    remove_column(:projects, :collapse_outdated_diff_comments)
  end
end

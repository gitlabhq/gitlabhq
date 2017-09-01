class CollapseOutdatedDiffComments < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    add_column_with_default(:projects,
                            :resolve_outdated_diff_discussions,
                            :boolean,
                            default: false)
  end

  def down
    remove_column(:projects, :resolve_outdated_diff_discussions)
  end
end

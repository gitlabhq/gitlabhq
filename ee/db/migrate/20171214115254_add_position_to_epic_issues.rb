class AddPositionToEpicIssues < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    default_position = Gitlab::Database::MAX_INT_VALUE / 2
    add_column_with_default(:epic_issues, :relative_position, :integer, default: default_position, allow_null: false)
  end

  def down
    remove_column(:epic_issues, :relative_position)
  end
end

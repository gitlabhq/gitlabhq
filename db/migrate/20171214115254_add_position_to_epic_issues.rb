class AddPositionToEpicIssues < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:epic_issues, :position, :integer, default: 1, allow_null: false)
    add_timestamps_with_timezone :epic_issues, null: true
  end

  def down
    remove_column(:epic_issues, :position)
    remove_column(:epic_issues, :created_at)
    remove_column(:epic_issues, :updated_at)
  end
end

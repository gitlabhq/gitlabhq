class AddPositionToEpicIssues < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:epic_issues, :position, :integer, default: Arel.sql('id'), allow_null: false)
  end

  def down
    remove_column(:epic_issues, :position)
  end
end

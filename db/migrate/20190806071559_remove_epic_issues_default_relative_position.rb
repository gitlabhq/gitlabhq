# frozen_string_literal: true

class RemoveEpicIssuesDefaultRelativePosition < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    # The column won't exist if someone installed EE, downgraded to CE
    # before it was added in EE, then tries to upgrade CE.
    if column_exists?(:epic_issues, :relative_position)
      change_column_null :epic_issues, :relative_position, true
      change_column_default :epic_issues, :relative_position, from: 1073741823, to: nil
    else
      add_column_with_default(:epic_issues, :relative_position, :integer, default: nil, allow_null: true) # rubocop:disable Migration/AddColumnWithDefault
    end
  end

  def down
    change_column_default :epic_issues, :relative_position, from: nil, to: 1073741823
    change_column_null :epic_issues, :relative_position, false
  end
end

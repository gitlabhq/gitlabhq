# frozen_string_literal: true

class RemoveEpicIssuesDefaultRelativePosition < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    change_column_null :epic_issues, :relative_position, true
    change_column_default :epic_issues, :relative_position, from: 1073741823, to: nil
  end
end

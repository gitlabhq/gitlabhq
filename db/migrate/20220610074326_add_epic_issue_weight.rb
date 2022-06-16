# frozen_string_literal: true

class AddEpicIssueWeight < Gitlab::Database::Migration[2.0]
  def change
    add_column :epics, :total_opened_issue_weight, :integer, default: 0, null: false
    add_column :epics, :total_closed_issue_weight, :integer, default: 0, null: false
    add_column :epics, :total_opened_issue_count, :integer, default: 0, null: false
    add_column :epics, :total_closed_issue_count, :integer, default: 0, null: false
  end
end

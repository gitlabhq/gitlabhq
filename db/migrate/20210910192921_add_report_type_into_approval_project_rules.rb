# frozen_string_literal: true

class AddReportTypeIntoApprovalProjectRules < Gitlab::Database::Migration[1.0]
  def up
    add_column :approval_project_rules, :report_type, :integer, limit: 2
  end

  def down
    remove_column :approval_project_rules, :report_type
  end
end

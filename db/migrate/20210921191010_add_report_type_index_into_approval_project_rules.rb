# frozen_string_literal: true

class AddReportTypeIndexIntoApprovalProjectRules < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_approval_project_rules_report_type'

  def up
    add_concurrent_index :approval_project_rules, :report_type, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :approval_project_rules, name: INDEX_NAME
  end
end

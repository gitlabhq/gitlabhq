# frozen_string_literal: true

class RemoveTmpIndexApprovalMergeRequestRulesOnReportType < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'tmp_index_approval_merge_request_rules_on_report_type_equal_one'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :approval_merge_request_rules, INDEX_NAME
  end

  def down
    add_concurrent_index :approval_merge_request_rules,
      [:id, :report_type],
      name: INDEX_NAME,
      where: "report_type = 1"
  end
end

# frozen_string_literal: true

class AddIndexMergeRequestIdCreatedAtOnScanFindingApprovalMergeRequestRules < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'scan_finding_approval_mr_rule_index_mr_id_and_created_at'
  SCAN_FINDING_REPORT_TYPE = 4

  disable_ddl_transaction!

  def up
    add_concurrent_index :approval_merge_request_rules, %i[merge_request_id created_at],
      where: "report_type = #{SCAN_FINDING_REPORT_TYPE}", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :approval_merge_request_rules, INDEX_NAME
  end
end

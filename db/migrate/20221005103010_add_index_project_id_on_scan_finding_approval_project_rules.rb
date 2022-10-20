# frozen_string_literal: true

class AddIndexProjectIdOnScanFindingApprovalProjectRules < Gitlab::Database::Migration[2.0]
  INDEX_NAME_ALL = 'scan_finding_approval_project_rule_index_project_id'
  INDEX_NAME_28D = 'scan_finding_approval_project_rule_index_created_at_project_id'
  SCAN_FINDING_REPORT_TYPE = 4

  disable_ddl_transaction!

  def up
    add_concurrent_index :approval_project_rules, %i[created_at project_id],
      where: "report_type = #{SCAN_FINDING_REPORT_TYPE}", name: INDEX_NAME_28D

    add_concurrent_index :approval_project_rules, :project_id,
      where: "report_type = #{SCAN_FINDING_REPORT_TYPE}", name: INDEX_NAME_ALL
  end

  def down
    remove_concurrent_index_by_name :approval_project_rules, INDEX_NAME_ALL
    remove_concurrent_index_by_name :approval_project_rules, INDEX_NAME_28D
  end
end

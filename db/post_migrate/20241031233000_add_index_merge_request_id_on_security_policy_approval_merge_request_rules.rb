# frozen_string_literal: true

class AddIndexMergeRequestIdOnSecurityPolicyApprovalMergeRequestRules < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  INDEX_NAME = 'security_policy_approval_mr_rule_index_merge_request_id'
  SCAN_FINDING_REPORT_TYPE = 4
  LICENSE_SCAN_REPORT_TYPE = 2
  ANY_MR_REPORT_TYPE = 5
  SECURITY_POLICIES_REPORT_TYPES = [SCAN_FINDING_REPORT_TYPE, LICENSE_SCAN_REPORT_TYPE, ANY_MR_REPORT_TYPE].freeze

  disable_ddl_transaction!

  def up
    add_concurrent_index :approval_merge_request_rules, :merge_request_id,
      where: "report_type IN (#{SECURITY_POLICIES_REPORT_TYPES.join(', ')})", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :approval_merge_request_rules, INDEX_NAME
  end
end

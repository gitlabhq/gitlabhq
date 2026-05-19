# frozen_string_literal: true

class RemoveTmpIdxOrphanedApprovalMergeRequestRules < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.0'

  INDEX_NAME = 'tmp_idx_orphaned_approval_merge_request_rules'

  def up
    remove_concurrent_index_by_name :approval_merge_request_rules, INDEX_NAME
  end

  def down
    add_concurrent_index :approval_merge_request_rules, :id,
      name: INDEX_NAME,
      where: '(report_type = ANY (ARRAY[2, 4])) AND security_orchestration_policy_configuration_id IS NULL'
  end
end

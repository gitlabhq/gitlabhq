# frozen_string_literal: true

class AddTemporaryIndexesForOrphanedApprovalRules < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  LICENSE_SCANNING = 2
  SCAN_FINDING = 4

  TMP_PROJECT_INDEX_NAME = 'tmp_idx_orphaned_approval_project_rules'
  TMP_MR_INDEX_NAME = 'tmp_idx_orphaned_approval_merge_request_rules'

  def up
    add_concurrent_index('approval_project_rules', :id, where: query_condition, name: TMP_PROJECT_INDEX_NAME)
    add_concurrent_index('approval_merge_request_rules', :id, where: query_condition, name: TMP_MR_INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name('approval_project_rules', TMP_PROJECT_INDEX_NAME)
    remove_concurrent_index_by_name('approval_merge_request_rules', TMP_MR_INDEX_NAME)
  end

  private

  def query_condition
    "report_type IN (#{LICENSE_SCANNING}, #{SCAN_FINDING}) AND security_orchestration_policy_configuration_id IS NULL"
  end
end

# frozen_string_literal: true

class AddIndexScanResultPolicyViolationsOnProjectIdPolicyRuleIdAndId < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  disable_ddl_transaction!

  INDEX_NAME = :idx_policy_violations_on_project_id_policy_rule_id_and_id
  TABLE_NAME = :scan_result_policy_violations

  def up
    add_concurrent_index(TABLE_NAME, %i[project_id approval_policy_rule_id id], name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end

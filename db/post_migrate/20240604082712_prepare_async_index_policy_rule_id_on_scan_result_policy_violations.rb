# frozen_string_literal: true

class PrepareAsyncIndexPolicyRuleIdOnScanResultPolicyViolations < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  INDEX_NAME = 'index_scan_result_policy_violations_on_approval_policy_rule_id'

  # TODO: Index to be created synchronously as part of https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155256
  def up
    prepare_async_index :scan_result_policy_violations, :approval_policy_rule_id, name: INDEX_NAME
  end

  def down
    unprepare_async_index :scan_result_policy_violations, :approval_policy_rule_id, name: INDEX_NAME
  end
end

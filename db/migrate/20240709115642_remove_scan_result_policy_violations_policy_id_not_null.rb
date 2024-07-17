# frozen_string_literal: true

class RemoveScanResultPolicyViolationsPolicyIdNotNull < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  def up
    execute "ALTER TABLE scan_result_policy_violations ALTER COLUMN scan_result_policy_id DROP NOT NULL"
  end

  def down
    execute "ALTER TABLE scan_result_policy_violations ALTER COLUMN scan_result_policy_id SET NOT NULL"
  end
end

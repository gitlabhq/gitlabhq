# frozen_string_literal: true

class AddScanStatusToScanResultPolicyViolation < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def up
    with_lock_retries do
      add_column :scan_result_policy_violations,
        :status, :integer, null: false, limit: 2, default: 1
    end
  end

  def down
    with_lock_retries do
      remove_column :scan_result_policy_violations,
        :status, :integer
    end
  end
end

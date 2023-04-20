# frozen_string_literal: true

class AddRoleApproversToScanResultPolicies < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :scan_result_policies, :role_approvers, :integer, array: true, default: []
  end
end

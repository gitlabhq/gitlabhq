# frozen_string_literal: true

class AddCustomRolesToScanResultPolicies < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '17.7'

  def change
    add_column :scan_result_policies, :custom_roles, :bigint, array: true, default: [], null: false
  end
end

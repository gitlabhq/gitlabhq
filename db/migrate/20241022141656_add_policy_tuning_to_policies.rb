# frozen_string_literal: true

class AddPolicyTuningToPolicies < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '17.6'

  def change
    add_column :scan_result_policies, :policy_tuning, :jsonb, null: false, default: {}
  end
end

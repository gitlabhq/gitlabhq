# frozen_string_literal: true

class AddActionIdxToScanResultPolicies < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '17.7'

  def change
    add_column :scan_result_policies, :action_idx, :smallint, default: 0, null: false
  end
end

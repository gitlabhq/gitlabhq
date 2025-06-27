# frozen_string_literal: true

class AddFallbackBehaviorToScanResultPolicyReads < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  def change
    add_column :scan_result_policies, :fallback_behavior, :jsonb, null: false, default: {}
  end
end

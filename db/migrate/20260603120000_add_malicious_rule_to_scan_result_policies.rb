# frozen_string_literal: true

class AddMaliciousRuleToScanResultPolicies < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def change
    add_column :scan_result_policies, :malicious_rule, :boolean
  end
end

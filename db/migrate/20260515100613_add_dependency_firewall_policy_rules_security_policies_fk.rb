# frozen_string_literal: true

class AddDependencyFirewallPolicyRulesSecurityPoliciesFk < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.1'

  def up
    add_concurrent_foreign_key :dependency_firewall_policy_rules, :security_policies,
      column: :security_policy_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :dependency_firewall_policy_rules, column: :security_policy_id
    end
  end
end

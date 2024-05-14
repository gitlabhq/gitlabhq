# frozen_string_literal: true

class EmptySecurityPolicies < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.0'

  def up
    truncate_tables!('security_policies', 'approval_policy_rules')
  end

  def down; end
end

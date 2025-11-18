# frozen_string_literal: true

class DropNotNullConstraintOnSecurityPolicyDismissalsSecurityPolicyId < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def up
    change_column_null :security_policy_dismissals, :security_policy_id, true
  end

  def down
    change_column_null :security_policy_dismissals, :security_policy_id, false
  end
end

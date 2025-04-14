# frozen_string_literal: true

class AddSecurityPoliciesHashConstraintToNamespaceSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  CONSTRAINT_NAME = 'check_namespace_settings_security_policies_is_hash'

  def up
    add_check_constraint(
      :namespace_settings,
      "(jsonb_typeof(security_policies) = 'object')",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint :namespace_settings, CONSTRAINT_NAME
  end
end

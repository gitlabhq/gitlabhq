# frozen_string_literal: true

class AddUsageBillingHashConstraintToNamespaceSettings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  CONSTRAINT_NAME = 'check_namespace_settings_usage_billing_is_hash'

  def up
    add_check_constraint(
      :namespace_settings,
      "(jsonb_typeof(usage_billing) = 'object')",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint :namespace_settings, CONSTRAINT_NAME
  end
end

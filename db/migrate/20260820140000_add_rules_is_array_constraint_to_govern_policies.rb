# frozen_string_literal: true

class AddRulesIsArrayConstraintToGovernPolicies < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_govern_policies_rules_is_array'

  def up
    add_check_constraint(
      :govern_policies,
      "(jsonb_typeof(rules) = 'array')",
      CONSTRAINT_NAME,
      validate: false
    )
  end

  def down
    remove_check_constraint :govern_policies, CONSTRAINT_NAME
  end
end

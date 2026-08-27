# frozen_string_literal: true

class ValidateRulesIsArrayConstraintOnGovernPolicies < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_govern_policies_rules_is_array'

  def up
    validate_check_constraint :govern_policies, CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end

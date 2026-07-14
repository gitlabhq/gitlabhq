# frozen_string_literal: true

class AddAllowedNullRuleConstraintToDependencyFirewallActivityStats < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.2'

  TABLE_NAME = :dependency_firewall_activity_stats
  CONSTRAINT_NAME = 'check_allowed_outcome_has_null_rule'

  def up
    # outcome 2 = `allowed`; an allowed event matches no rule, so its rule_id must be NULL.
    add_check_constraint(
      TABLE_NAME,
      '(outcome <> 2) OR (dependency_firewall_policy_rule_id IS NULL)',
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint(TABLE_NAME, CONSTRAINT_NAME)
  end
end

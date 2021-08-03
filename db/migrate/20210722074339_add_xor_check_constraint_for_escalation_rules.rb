# frozen_string_literal: true

class AddXorCheckConstraintForEscalationRules < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'escalation_rules_one_of_oncall_schedule_or_user'

  def up
    add_check_constraint :incident_management_escalation_rules, 'num_nonnulls(oncall_schedule_id, user_id) = 1', CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :incident_management_escalation_rules, CONSTRAINT_NAME
  end
end

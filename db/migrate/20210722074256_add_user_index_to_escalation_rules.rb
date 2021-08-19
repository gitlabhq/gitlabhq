# frozen_string_literal: true

class AddUserIndexToEscalationRules < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  USER_INDEX_NAME = 'index_escalation_rules_on_user'
  OLD_UNIQUE_INDEX_NAME = 'index_on_policy_schedule_status_elapsed_time_escalation_rules'
  NEW_UNIQUE_INDEX_NAME = 'index_escalation_rules_on_all_attributes'

  def up
    remove_concurrent_index_by_name :incident_management_escalation_rules, OLD_UNIQUE_INDEX_NAME

    add_concurrent_index :incident_management_escalation_rules, :user_id, name: USER_INDEX_NAME
    add_concurrent_index :incident_management_escalation_rules,
      [:policy_id, :oncall_schedule_id, :status, :elapsed_time_seconds, :user_id],
      unique: true,
      name: NEW_UNIQUE_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :incident_management_escalation_rules, USER_INDEX_NAME
    remove_concurrent_index_by_name :incident_management_escalation_rules, NEW_UNIQUE_INDEX_NAME

    exec_query 'DELETE FROM incident_management_escalation_rules WHERE oncall_schedule_id IS NULL'

    add_concurrent_index :incident_management_escalation_rules,
      [:policy_id, :oncall_schedule_id, :status, :elapsed_time_seconds],
      unique: true,
      name: OLD_UNIQUE_INDEX_NAME
  end
end

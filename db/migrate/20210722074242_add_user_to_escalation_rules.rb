# frozen_string_literal: true

class AddUserToEscalationRules < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      add_column :incident_management_escalation_rules, :user_id, :bigint, null: true
    end
  end

  def down
    with_lock_retries do
      remove_column :incident_management_escalation_rules, :user_id
    end
  end
end

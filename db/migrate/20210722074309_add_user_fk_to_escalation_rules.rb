# frozen_string_literal: true

class AddUserFkToEscalationRules < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :incident_management_escalation_rules, :users, column: :user_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :incident_management_escalation_rules, column: :user_id
    end
  end
end

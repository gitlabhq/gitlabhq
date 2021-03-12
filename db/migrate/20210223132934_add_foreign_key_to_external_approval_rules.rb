# frozen_string_literal: true

class AddForeignKeyToExternalApprovalRules < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :external_approval_rules_protected_branches, :external_approval_rules, column: :external_approval_rule_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :external_approval_rules_protected_branches, column: :external_approval_rule_id
    end
  end
end

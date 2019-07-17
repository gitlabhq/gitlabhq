# frozen_string_literal: true

class AddIndexToApprovalProjectRulesRuleType < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :approval_project_rules, :rule_type
  end

  def down
    remove_concurrent_index :approval_project_rules, :rule_type
  end
end

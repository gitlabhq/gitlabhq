# frozen_string_literal: true

class AddRuleTypeToApprovalProjectRules < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :approval_project_rules, :rule_type, :integer, limit: 2, default: 0, allow_null: false # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column :approval_project_rules, :rule_type
  end
end

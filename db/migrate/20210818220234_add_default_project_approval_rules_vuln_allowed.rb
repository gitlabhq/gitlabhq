# frozen_string_literal: true

class AddDefaultProjectApprovalRulesVulnAllowed < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DEFAULT_VALUE = 0

  def up
    change_column_default :approval_project_rules, :vulnerabilities_allowed, DEFAULT_VALUE

    update_column_in_batches(:approval_project_rules, :vulnerabilities_allowed, DEFAULT_VALUE) do |table, query|
      query.where(table[:vulnerabilities_allowed].eq(nil))
    end

    change_column_null :approval_project_rules, :vulnerabilities_allowed, false
  end

  def down
    change_column_default :approval_project_rules, :vulnerabilities_allowed, nil
    change_column_null :approval_project_rules, :vulnerabilities_allowed, true
  end
end

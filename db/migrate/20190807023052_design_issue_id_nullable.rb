# frozen_string_literal: true

class DesignIssueIdNullable < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    change_column_null :design_management_designs, :issue_id, true
  end
end

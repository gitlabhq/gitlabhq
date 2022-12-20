# frozen_string_literal: true

class AddDefaultForApprovalProjectRulesScanners < Gitlab::Database::Migration[2.0]
  def up
    change_column_default :approval_project_rules, :scanners, from: nil, to: []
  end

  def down
    change_column_default :approval_project_rules, :scanners, from: [], to: nil
  end
end

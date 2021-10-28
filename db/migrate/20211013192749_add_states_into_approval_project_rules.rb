# frozen_string_literal: true

class AddStatesIntoApprovalProjectRules < Gitlab::Database::Migration[1.0]
  def up
    add_column :approval_project_rules, :vulnerability_states, :text, array: true, null: false, default: ['newly_detected']
  end

  def down
    remove_column :approval_project_rules, :vulnerability_states
  end
end

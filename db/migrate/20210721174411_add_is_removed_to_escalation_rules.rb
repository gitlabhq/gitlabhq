# frozen_string_literal: true

class AddIsRemovedToEscalationRules < ActiveRecord::Migration[6.1]
  def change
    add_column :incident_management_escalation_rules, :is_removed, :boolean, null: false, default: false
  end
end

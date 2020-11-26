# frozen_string_literal: true

class AddRegulatedToComplianceFrameworks < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column(:compliance_management_frameworks, :regulated, :boolean, default: true, null: false)
  end
end

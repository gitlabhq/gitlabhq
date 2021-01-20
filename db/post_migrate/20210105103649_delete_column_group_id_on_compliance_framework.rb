# frozen_string_literal: true

class DeleteColumnGroupIdOnComplianceFramework < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    remove_column :compliance_management_frameworks, :group_id, :bigint
  end
end

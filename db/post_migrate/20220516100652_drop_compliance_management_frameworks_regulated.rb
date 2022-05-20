# frozen_string_literal: true

class DropComplianceManagementFrameworksRegulated < Gitlab::Database::Migration[2.0]
  def up
    remove_column :compliance_management_frameworks, :regulated
  end

  def down
    add_column :compliance_management_frameworks, :regulated, :boolean, default: true
  end
end

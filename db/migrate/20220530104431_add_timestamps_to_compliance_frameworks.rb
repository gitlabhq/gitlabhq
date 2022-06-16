# frozen_string_literal: true

class AddTimestampsToComplianceFrameworks < Gitlab::Database::Migration[2.0]
  def up
    add_column :compliance_management_frameworks, :created_at, :datetime_with_timezone, null: true
    add_column :compliance_management_frameworks, :updated_at, :datetime_with_timezone, null: true
  end

  def down
    remove_column :compliance_management_frameworks, :created_at
    remove_column :compliance_management_frameworks, :updated_at
  end
end

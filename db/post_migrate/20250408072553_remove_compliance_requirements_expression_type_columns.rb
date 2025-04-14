# frozen_string_literal: true

class RemoveComplianceRequirementsExpressionTypeColumns < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  def up
    remove_column :compliance_requirements, :control_expression, if_exists: true
    remove_column :compliance_requirements, :requirement_type, if_exists: true
  end

  def down
    add_column(:compliance_requirements, :control_expression, :text, if_not_exists: true)
    add_text_limit :compliance_requirements, :control_expression, 2048

    add_column(:compliance_requirements, :requirement_type, :smallint, null: false, default: 0, if_not_exists: true)
  end
end

# frozen_string_literal: true

class AddColumnsTypeExpressionToComplianceRequirements < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :compliance_requirements, :control_expression, :text, if_not_exists: true
      add_column :compliance_requirements, :requirement_type, :smallint, null: false, default: 0, if_not_exists: true
    end

    add_text_limit :compliance_requirements, :control_expression, 2048
  end

  def down
    with_lock_retries do
      remove_column :compliance_requirements, :control_expression, if_exists: true
      remove_column :compliance_requirements, :requirement_type, if_exists: true
    end
  end
end

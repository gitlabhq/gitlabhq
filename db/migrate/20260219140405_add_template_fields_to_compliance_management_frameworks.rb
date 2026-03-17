# frozen_string_literal: true

class AddTemplateFieldsToComplianceManagementFrameworks < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.10'

  def up
    with_lock_retries do
      add_column :compliance_management_frameworks, :template_id, :text, if_not_exists: true
      add_column :compliance_management_frameworks, :template_version, :integer, if_not_exists: true
    end

    add_text_limit :compliance_management_frameworks, :template_id, 255, validate: false
  end

  def down
    with_lock_retries do
      remove_column :compliance_management_frameworks, :template_id, if_exists: true
      remove_column :compliance_management_frameworks, :template_version, if_exists: true
    end
  end
end

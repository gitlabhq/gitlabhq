# frozen_string_literal: true

class AddExternalControlNameToComplianceRequirementsControls < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.0'

  def up
    with_lock_retries do
      add_column :compliance_requirements_controls, :external_control_name, :text, null: true
    end

    add_text_limit :compliance_requirements_controls, :external_control_name, 255
  end

  def down
    with_lock_retries do
      remove_column :compliance_requirements_controls, :external_control_name, if_exists: true
    end
  end
end

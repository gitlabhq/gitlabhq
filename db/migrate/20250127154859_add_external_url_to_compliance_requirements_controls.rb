# frozen_string_literal: true

class AddExternalUrlToComplianceRequirementsControls < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :compliance_requirements_controls, :external_url, :text, if_not_exists: true
    end

    add_text_limit :compliance_requirements_controls, :external_url, 1024
  end

  def down
    with_lock_retries do
      remove_column :compliance_requirements_controls, :external_url, if_exists: true
    end
  end
end

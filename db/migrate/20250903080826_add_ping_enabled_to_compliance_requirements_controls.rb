# frozen_string_literal: true

class AddPingEnabledToComplianceRequirementsControls < Gitlab::Database::Migration[2.3]
  milestone '18.4'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :compliance_requirements_controls, :ping_enabled, :boolean,
        default: true, null: false, if_not_exists: true
    end
  end

  def down
    with_lock_retries do
      remove_column :compliance_requirements_controls, :ping_enabled, if_exists: true
    end
  end
end

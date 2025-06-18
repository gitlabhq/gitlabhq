# frozen_string_literal: true

class AddConstraintsToApplicationSettingsSecurityAndComplianceSettings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  CONSTRAINT_NAME = 'check_security_and_compliance_settings_is_hash'

  def up
    add_check_constraint :application_settings, "(jsonb_typeof(security_and_compliance_settings) = 'object')",
      CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
  end
end

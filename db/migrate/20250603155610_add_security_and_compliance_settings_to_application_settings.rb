# frozen_string_literal: true

class AddSecurityAndComplianceSettingsToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  def change
    add_column :application_settings, :security_and_compliance_settings, :jsonb, default: {}, null: false
  end
end

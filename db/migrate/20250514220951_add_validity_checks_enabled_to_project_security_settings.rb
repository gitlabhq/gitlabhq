# frozen_string_literal: true

class AddValidityChecksEnabledToProjectSecuritySettings < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    add_column :project_security_settings, :validity_checks_enabled, :boolean, null: false,
      default: false
  end
end

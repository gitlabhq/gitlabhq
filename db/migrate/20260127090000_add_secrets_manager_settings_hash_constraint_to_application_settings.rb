# frozen_string_literal: true

class AddSecretsManagerSettingsHashConstraintToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '18.9'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_application_settings_secrets_manager_settings_is_hash'

  def up
    add_check_constraint(
      :application_settings,
      "jsonb_typeof(secrets_manager_settings) = 'object'",
      CONSTRAINT_NAME,
      validate: true
    )
  end

  def down
    remove_check_constraint(:application_settings, CONSTRAINT_NAME)
  end
end

# frozen_string_literal: true

class AddOauthProviderSettingsConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.8'
  disable_ddl_transaction!
  CONSTRAINT_NAME = 'application_settings_oauth_provider_settings_hash'

  def up
    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(oauth_provider) = 'object')",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint(
      :application_settings,
      CONSTRAINT_NAME
    )
  end
end

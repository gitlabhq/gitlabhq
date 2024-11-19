# frozen_string_literal: true

class AddIdentityVerificationSettingsJsonColumnToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  def up
    add_column :application_settings, :identity_verification_settings, :jsonb, default: {}, null: false

    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(identity_verification_settings) = 'object')",
      'check_identity_verification_settings_is_hash'
    )
  end

  def down
    remove_column :application_settings, :identity_verification_settings
  end
end

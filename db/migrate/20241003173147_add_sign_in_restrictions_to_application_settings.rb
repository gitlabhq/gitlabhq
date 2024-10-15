# frozen_string_literal: true

class AddSignInRestrictionsToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  def up
    add_column :application_settings, :sign_in_restrictions, :jsonb, default: {}, null: false, if_not_exists: true

    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(sign_in_restrictions) = 'object')",
      'check_application_settings_sign_in_restrictions_is_hash'
    )
  end

  def down
    remove_column :application_settings, :sign_in_restrictions
  end
end

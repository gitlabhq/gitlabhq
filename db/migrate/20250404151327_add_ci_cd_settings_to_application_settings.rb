# frozen_string_literal: true

class AddCiCdSettingsToApplicationSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.11'

  CONSTRAINT_NAME = 'check_application_settings_ci_cd_settings_is_hash'

  def up
    with_lock_retries do
      add_column :application_settings, :ci_cd_settings, :jsonb, default: {}, null: false, if_not_exists: true
    end

    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(ci_cd_settings) = 'object')",
      CONSTRAINT_NAME
    )
  end

  def down
    with_lock_retries do
      remove_column :application_settings, :ci_cd_settings, if_exists: true
    end
  end
end

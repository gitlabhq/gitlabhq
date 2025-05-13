# frozen_string_literal: true

class AddNotNullConstraintToVsCodeSettingsContextHash < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_vs_code_settings_settings_context_hash_nullable'

  def up
    add_check_constraint(
      :vs_code_settings,
      "(setting_type = 'extensions' AND settings_context_hash IS NOT NULL) OR " \
        "(setting_type != 'extensions' AND settings_context_hash IS NULL)",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint :vs_code_settings, CONSTRAINT_NAME
  end
end

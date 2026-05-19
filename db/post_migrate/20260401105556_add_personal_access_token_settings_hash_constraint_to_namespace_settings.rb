# frozen_string_literal: true

class AddPersonalAccessTokenSettingsHashConstraintToNamespaceSettings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.0'

  CONSTRAINT_NAME = 'check_namespace_settings_pat_settings_is_hash'

  def up
    add_check_constraint(
      :namespace_settings,
      "(jsonb_typeof(personal_access_token_settings) = 'object')",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint :namespace_settings, CONSTRAINT_NAME
  end
end

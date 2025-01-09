# frozen_string_literal: true

class AddO11ySettingsHashConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.8'

  CONSTRAINT_NAME = 'check_application_settings_o11y_settings_is_hash'

  def up
    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(observability_settings) = 'object')",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
  end
end

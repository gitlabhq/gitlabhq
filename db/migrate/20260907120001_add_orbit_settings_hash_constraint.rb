# frozen_string_literal: true

class AddOrbitSettingsHashConstraint < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.4'

  CONSTRAINT_NAME = 'check_application_settings_orbit_settings_is_hash'

  def up
    add_check_constraint(
      :application_settings,
      "jsonb_typeof(orbit_settings) = 'object'",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
  end
end

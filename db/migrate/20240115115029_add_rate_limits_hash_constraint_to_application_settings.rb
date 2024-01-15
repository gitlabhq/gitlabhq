# frozen_string_literal: true

class AddRateLimitsHashConstraintToApplicationSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.9'

  CONSTRAINT_NAME = 'check_application_settings_rate_limits_is_hash'

  def up
    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(rate_limits) = 'object')",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
  end
end

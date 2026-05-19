# frozen_string_literal: true

class AddDiffLimitsHashConstraintToApplicationSettings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.0'

  CONSTRAINT_NAME = 'check_application_settings_diff_limits_is_hash'

  def up
    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(diff_limits) = 'object')",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
  end
end

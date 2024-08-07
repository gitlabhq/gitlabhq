# frozen_string_literal: true

class AddDuoWorkflowHashConstraintToApplicationSetting < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_application_settings_duo_workflow_is_hash'
  def up
    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(duo_workflow) = 'object')",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
  end
end

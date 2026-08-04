# frozen_string_literal: true

class AddNotNullConstraintToAiSettingsOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  TABLE_NAME = :ai_settings
  COLUMN_NAME = :organization_id

  def up
    add_not_null_constraint(TABLE_NAME, COLUMN_NAME)
  end

  def down
    remove_not_null_constraint(TABLE_NAME, COLUMN_NAME)
  end
end

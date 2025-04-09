# frozen_string_literal: true

class AddDatabaseReindexingHashConstraintToApplicationSetting < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_application_settings_database_reindexing_is_hash'

  def up
    add_check_constraint(:application_settings, "(jsonb_typeof(database_reindexing) = 'object')", CONSTRAINT_NAME)
  end

  def down
    remove_check_constraint(:application_settings, CONSTRAINT_NAME)
  end
end

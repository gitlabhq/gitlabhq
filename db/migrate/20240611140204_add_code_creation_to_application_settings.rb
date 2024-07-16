# frozen_string_literal: true

class AddCodeCreationToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_application_settings_code_creation_is_hash'

  def up
    add_column :application_settings, :code_creation, :jsonb, default: {}, null: false, if_not_exists: true
    add_check_constraint(:application_settings, "(jsonb_typeof(code_creation) = 'object')", CONSTRAINT_NAME)
  end

  def down
    remove_column :application_settings, :code_creation
  end
end

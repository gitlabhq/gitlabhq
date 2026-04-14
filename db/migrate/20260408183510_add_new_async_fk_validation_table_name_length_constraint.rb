# frozen_string_literal: true

class AddNewAsyncFkValidationTableNameLengthConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_async_fk_validation_table_name_length'

  def up
    add_text_limit :postgres_async_foreign_key_validations, :table_name, 127, constraint_name: CONSTRAINT_NAME,
      validate: false
  end

  def down
    remove_text_limit :postgres_async_foreign_key_validations, :table_name, constraint_name: CONSTRAINT_NAME
  end
end

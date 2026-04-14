# frozen_string_literal: true

class ValidateAsyncFkValidationTableNameLengthConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  disable_ddl_transaction!

  def up
    validate_text_limit :postgres_async_foreign_key_validations, :table_name,
      constraint_name: 'check_async_fk_validation_table_name_length'
  end

  def down
    # no-op because we cannot invalidate a constraint
  end
end

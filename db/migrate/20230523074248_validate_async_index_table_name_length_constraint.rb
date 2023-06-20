# frozen_string_literal: true

class ValidateAsyncIndexTableNameLengthConstraint < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    validate_text_limit :postgres_async_indexes, :table_name, constraint_name: 'check_schema_and_name_length'
  end

  def down
    # no-op because we cannot invalidate a constraint
  end
end

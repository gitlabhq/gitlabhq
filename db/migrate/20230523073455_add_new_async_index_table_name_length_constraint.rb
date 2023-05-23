# frozen_string_literal: true

class AddNewAsyncIndexTableNameLengthConstraint < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_schema_and_name_length'

  def up
    add_text_limit :postgres_async_indexes, :table_name, 127, constraint_name: CONSTRAINT_NAME, validate: false
  end

  def down
    remove_text_limit :postgres_async_indexes, :table_name, constraint_name: CONSTRAINT_NAME
  end
end

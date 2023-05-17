# frozen_string_literal: true

class AddConstraintTypeToPostgresAsyncConstraintValidation < Gitlab::Database::Migration[2.1]
  def change
    add_column :postgres_async_foreign_key_validations, :constraint_type, :integer, null: false, default: 0, limit: 2
  end
end

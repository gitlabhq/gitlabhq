# frozen_string_literal: true

class RemoveOldAsyncFkValidationTableNameLengthConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  disable_ddl_transaction!

  OLD_LENGTH_LIMIT = 63

  def up
    remove_text_limit :postgres_async_foreign_key_validations, :table_name
  end

  def down
    # Remove items that might break the old length validation. (unlikely to happen)
    define_batchable_model('postgres_async_foreign_key_validations').each_batch do |validations|
      validations.where('char_length(table_name) > ?', OLD_LENGTH_LIMIT).delete_all
    end

    add_text_limit :postgres_async_foreign_key_validations, :table_name, OLD_LENGTH_LIMIT
  end
end

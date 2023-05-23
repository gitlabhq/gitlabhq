# frozen_string_literal: true

class RemoveOldAsyncIndexTableNameLengthConstraint < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  OLD_LENGTH_LIMIT = 63

  def up
    remove_text_limit :postgres_async_indexes, :table_name
  end

  def down
    # Remove items that might break the old length validation. (unlikely to happen)
    define_batchable_model('postgres_async_indexes').each_batch do |indexes|
      indexes.where('CHAR_LENGTH(table_name) > ?', OLD_LENGTH_LIMIT).delete_all
    end

    add_text_limit :postgres_async_indexes, :table_name, OLD_LENGTH_LIMIT
  end
end

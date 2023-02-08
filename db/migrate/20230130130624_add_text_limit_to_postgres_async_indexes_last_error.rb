# frozen_string_literal: true

class AddTextLimitToPostgresAsyncIndexesLastError < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :postgres_async_indexes, :last_error, 10_000
  end

  def down
    remove_text_limit :postgres_async_indexes, :last_error
  end
end

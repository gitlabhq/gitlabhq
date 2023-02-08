# frozen_string_literal: true

class AddAttemptsAndLastErrorToPostgresAsyncIndexes < Gitlab::Database::Migration[2.1]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20230130130624_add_text_limit_to_postgres_async_indexes_last_error.rb
  def change
    add_column :postgres_async_indexes, :attempts, :integer, null: false, default: 0
    add_column :postgres_async_indexes, :last_error, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end

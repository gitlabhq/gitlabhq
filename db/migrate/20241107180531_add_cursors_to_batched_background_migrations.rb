# frozen_string_literal: true

class AddCursorsToBatchedBackgroundMigrations < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    add_column :batched_background_migrations, :min_cursor, :jsonb, null: true
    add_column :batched_background_migrations, :max_cursor, :jsonb, null: true
  end
end

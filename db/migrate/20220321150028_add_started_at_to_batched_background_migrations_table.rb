# frozen_string_literal: true

class AddStartedAtToBatchedBackgroundMigrationsTable < Gitlab::Database::Migration[1.0]
  def change
    add_column :batched_background_migrations, :started_at, :datetime_with_timezone
  end
end

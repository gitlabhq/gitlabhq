# frozen_string_literal: true

class AddFinishedAtColumnToBatchedBackgroundMigrationsTable < Gitlab::Database::Migration[2.1]
  def change
    add_column :batched_background_migrations, :finished_at, :datetime_with_timezone
  end
end

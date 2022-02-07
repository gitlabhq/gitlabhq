# frozen_string_literal: true

class AddBatchedMigrationMaxBatch < Gitlab::Database::Migration[1.0]
  def change
    add_column :batched_background_migrations, :max_batch_size, :integer
  end
end

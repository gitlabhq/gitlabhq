# frozen_string_literal: true

class AddDatabaseMaxRunningBatchedBackgroundMigrationsToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :database_max_running_batched_background_migrations,
      :integer, null: false, default: 2
  end
end

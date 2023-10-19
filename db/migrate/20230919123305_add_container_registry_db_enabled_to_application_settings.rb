# frozen_string_literal: true

class AddContainerRegistryDbEnabledToApplicationSettings < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :application_settings, :container_registry_db_enabled, :boolean, null: false, default: false
  end
end

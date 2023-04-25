# frozen_string_literal: true

class AddContainerRegistryExpirationPoliciesCachingToApplicationSettings < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def up
    add_column :application_settings, :container_registry_expiration_policies_caching, :boolean, null: false, default: true
  end

  def down
    remove_column :application_settings, :container_registry_expiration_policies_caching
  end
end

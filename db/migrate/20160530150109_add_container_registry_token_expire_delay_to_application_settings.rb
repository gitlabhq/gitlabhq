# This is ONLINE migration

class AddContainerRegistryTokenExpireDelayToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  def change
    add_column :application_settings, :container_registry_token_expire_delay, :integer, default: 5

    # Set expire delay to 5 minutes for existing settings
    execute("update application_settings set container_registry_token_expire_delay = 5")
  end
end

# frozen_string_literal: true

class AddPaConfiguratorBaseToProjectSettings < Gitlab::Database::Migration[2.1]
  enable_lock_retries!
  def up
    add_column :project_settings, :encrypted_product_analytics_configurator_connection_string, :binary
    add_column :project_settings, :encrypted_product_analytics_configurator_connection_string_iv, :binary
  end

  def down
    remove_column :project_settings, :encrypted_product_analytics_configurator_connection_string
    remove_column :project_settings, :encrypted_product_analytics_configurator_connection_string_iv
  end
end

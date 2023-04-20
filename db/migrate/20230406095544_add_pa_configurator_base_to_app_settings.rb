# frozen_string_literal: true

class AddPaConfiguratorBaseToAppSettings < Gitlab::Database::Migration[2.1]
  def up
    add_column :application_settings, :encrypted_product_analytics_configurator_connection_string, :binary
    add_column :application_settings, :encrypted_product_analytics_configurator_connection_string_iv, :binary
  end

  def down
    remove_column :application_settings, :encrypted_product_analytics_configurator_connection_string
    remove_column :application_settings, :encrypted_product_analytics_configurator_connection_string_iv
  end
end

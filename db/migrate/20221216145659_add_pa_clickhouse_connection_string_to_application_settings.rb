# frozen_string_literal: true
class AddPaClickhouseConnectionStringToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :encrypted_product_analytics_clickhouse_connection_string, :binary
    add_column :application_settings, :encrypted_product_analytics_clickhouse_connection_string_iv, :binary
  end
end

# frozen_string_literal: true

class RemoveApplicationSettingsClickhouseConnectionString < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    remove_column :application_settings, :clickhouse_connection_string
  end

  def down
    unless column_exists?(:application_settings, :clickhouse_connection_string)
      # rubocop:disable Migration/SchemaAdditionMethodsNoPost
      add_column :application_settings, :clickhouse_connection_string, :text
      # rubocop:enable Migration/SchemaAdditionMethodsNoPost
    end

    add_text_limit :application_settings, :clickhouse_connection_string, 1024
  end
end

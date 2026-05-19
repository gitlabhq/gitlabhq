# frozen_string_literal: true

class AddMcpServerSettingsToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    add_column :application_settings, :mcp_server_settings, :jsonb, default: {}, null: false
  end
end

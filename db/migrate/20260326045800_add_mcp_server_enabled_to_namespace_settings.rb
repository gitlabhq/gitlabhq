# frozen_string_literal: true

class AddMcpServerEnabledToNamespaceSettings < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    add_column :namespace_settings, :mcp_server_enabled, :boolean
  end
end

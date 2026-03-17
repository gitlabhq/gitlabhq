# frozen_string_literal: true

class AddExpiresAtToAiCatalogMcpServersUsers < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def change
    add_column :ai_catalog_mcp_servers_users, :expires_at, :datetime_with_timezone, null: true
  end
end

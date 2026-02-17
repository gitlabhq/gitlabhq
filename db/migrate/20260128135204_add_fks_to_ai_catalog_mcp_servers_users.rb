# frozen_string_literal: true

class AddFksToAiCatalogMcpServersUsers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.9'

  def up
    add_concurrent_foreign_key :ai_catalog_mcp_servers_users, :ai_catalog_mcp_servers,
      column: :ai_catalog_mcp_server_id, on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :ai_catalog_mcp_servers_users, :ai_catalog_mcp_servers,
      column: :ai_catalog_mcp_server_id, on_delete: :cascade
  end
end

# frozen_string_literal: true

class AddFksToAiCatalogMcpServersUsersUsers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.9'

  def up
    add_concurrent_foreign_key :ai_catalog_mcp_servers_users, :users, column: :user_id, on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :ai_catalog_mcp_servers_users, :users, column: :user_id, on_delete: :cascade
  end
end

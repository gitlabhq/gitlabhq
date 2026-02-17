# frozen_string_literal: true

class CreateAiCatalogMcpServersUsers < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def change
    create_table :ai_catalog_mcp_servers_users do |t|
      t.timestamps_with_timezone null: false
      t.references :organization,
        foreign_key: { on_delete: :cascade },
        index: { name: 'idx_ai_catalog_mcp_servers_users_on_organization_id' },
        null: false
      t.bigint :ai_catalog_mcp_server_id, null: false
      t.bigint :user_id, null: false, index: true
      t.jsonb :token
      t.jsonb :refresh_token

      t.index [:ai_catalog_mcp_server_id, :user_id], unique: true, name: 'index_mcp_servers_users_on_server_and_user'
    end
  end
end

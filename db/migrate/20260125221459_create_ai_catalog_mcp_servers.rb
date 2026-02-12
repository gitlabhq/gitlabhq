# frozen_string_literal: true

class CreateAiCatalogMcpServers < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def change
    create_table :ai_catalog_mcp_servers do |t|
      t.timestamps_with_timezone null: false
      t.references :organization,
        foreign_key: { on_delete: :cascade },
        index: { name: 'idx_ai_catalog_mcp_servers_on_organization_id' },
        null: false
      t.bigint :created_by_id, null: true
      t.integer :transport, limit: 2, null: false, default: 0
      t.integer :auth_type, limit: 2, null: false, default: 0
      t.text :name, null: false, limit: 255
      t.text :description, limit: 2_048
      t.text :url, null: false, limit: 2_048
      t.text :homepage_url, limit: 2_048
      t.text :oauth_client_xid, limit: 255
      t.jsonb :oauth_client_secret

      t.index :created_by_id
    end
  end
end

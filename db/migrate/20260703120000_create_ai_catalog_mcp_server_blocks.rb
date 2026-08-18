# frozen_string_literal: true

class CreateAiCatalogMcpServerBlocks < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  UNIQUE_INDEX_NAME = 'idx_ai_catalog_mcp_server_blocks_on_org_ns_server'
  NAMESPACE_INDEX_NAME = 'idx_ai_catalog_mcp_server_blocks_on_ns_and_server'

  def change
    create_table :ai_catalog_mcp_server_blocks do |t|
      t.timestamps_with_timezone null: false
      # Foreign keys are added in separate migrations (one per key) per the migration style guide.
      t.bigint :organization_id, null: false
      t.bigint :namespace_id, null: false
      t.bigint :ai_catalog_mcp_server_id, null: false
      t.bigint :created_by_id, null: true

      t.index [:organization_id, :namespace_id, :ai_catalog_mcp_server_id], unique: true, name: UNIQUE_INDEX_NAME
      t.index [:namespace_id, :ai_catalog_mcp_server_id], name: NAMESPACE_INDEX_NAME
      t.index :ai_catalog_mcp_server_id, name: 'idx_ai_catalog_mcp_server_blocks_on_mcp_server_id'
      t.index :created_by_id
    end
  end
end

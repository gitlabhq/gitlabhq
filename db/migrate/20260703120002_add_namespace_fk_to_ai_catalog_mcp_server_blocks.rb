# frozen_string_literal: true

class AddNamespaceFkToAiCatalogMcpServerBlocks < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.3'

  def up
    add_concurrent_foreign_key :ai_catalog_mcp_server_blocks, :namespaces,
      column: :namespace_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :ai_catalog_mcp_server_blocks, column: :namespace_id
    end
  end
end

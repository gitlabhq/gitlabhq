# frozen_string_literal: true

class AddCreatedByFkToAiCatalogMcpServerBlocks < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.3'

  def up
    add_concurrent_foreign_key :ai_catalog_mcp_server_blocks, :users,
      column: :created_by_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :ai_catalog_mcp_server_blocks, column: :created_by_id
    end
  end
end

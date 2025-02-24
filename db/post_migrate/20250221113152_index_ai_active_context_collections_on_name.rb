# frozen_string_literal: true

class IndexAiActiveContextCollectionsOnName < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'uniq_idx_ai_active_context_collections_on_connection_id_name'

  milestone '17.10'
  disable_ddl_transaction!

  def up
    add_concurrent_index :ai_active_context_collections, [:connection_id, :name], unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ai_active_context_collections, INDEX_NAME
  end
end

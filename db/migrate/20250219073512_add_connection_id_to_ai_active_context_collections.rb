# frozen_string_literal: true

class AddConnectionIdToAiActiveContextCollections < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  def up
    # drop records before adding new column
    truncate_tables!('ai_active_context_collections')

    add_column :ai_active_context_collections, :connection_id, :bigint, null: false, if_not_exists: true # rubocop:disable Rails/NotNullColumn -- table is empty
    add_concurrent_foreign_key :ai_active_context_collections, :ai_active_context_connections, column: :connection_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_column :ai_active_context_collections, :connection_id, if_exists: true
    end
  end
end

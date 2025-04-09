# frozen_string_literal: true

class IndexAiConversationThreadsOnCreatedAt < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_ai_conversation_threads_on_created_at'

  disable_ddl_transaction!
  milestone '17.11'

  def up
    add_concurrent_index :ai_conversation_threads, :created_at, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :ai_conversation_threads, :created_at, name: INDEX_NAME
  end
end

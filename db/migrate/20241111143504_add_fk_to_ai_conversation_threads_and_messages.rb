# frozen_string_literal: true

class AddFkToAiConversationThreadsAndMessages < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ai_conversation_threads, :organizations, column: :organization_id, on_delete: :cascade
    add_concurrent_foreign_key :ai_conversation_threads, :users, column: :user_id, on_delete: :cascade
    add_concurrent_foreign_key :ai_conversation_messages, :ai_agent_versions, column: :agent_version_id,
      on_delete: :nullify
    add_concurrent_foreign_key :ai_conversation_messages, :organizations, column: :organization_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :ai_conversation_threads, column: :organization_id
      remove_foreign_key :ai_conversation_threads, column: :user_id
      remove_foreign_key :ai_conversation_messages, column: :agent_version_id
      remove_foreign_key :ai_conversation_messages, column: :organization_id
    end
  end
end

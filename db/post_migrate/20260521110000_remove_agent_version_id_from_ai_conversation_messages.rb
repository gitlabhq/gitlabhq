# frozen_string_literal: true

class RemoveAgentVersionIdFromAiConversationMessages < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.2'

  def up
    with_lock_retries do
      remove_column :ai_conversation_messages, :agent_version_id, if_exists: true
    end
  end

  def down
    return if column_exists?(:ai_conversation_messages, :agent_version_id)

    with_lock_retries do
      add_column :ai_conversation_messages, :agent_version_id, :bigint
    end

    add_concurrent_index :ai_conversation_messages, :agent_version_id,
      name: :index_ai_conversation_messages_on_agent_version_id

    add_concurrent_foreign_key :ai_conversation_messages, :ai_agent_versions,
      column: :agent_version_id, on_delete: :nullify, name: :fk_b5d715b1e4
  end
end

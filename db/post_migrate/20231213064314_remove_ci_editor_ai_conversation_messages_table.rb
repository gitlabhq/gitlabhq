# frozen_string_literal: true

class RemoveCiEditorAiConversationMessagesTable < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  def up
    drop_table :ci_editor_ai_conversation_messages, if_exists: true
  end

  def down
    create_table :ci_editor_ai_conversation_messages do |t|
      t.bigint :user_id,
        null: false
      t.bigint :project_id,
        null: false
      t.timestamps_with_timezone null: false
      t.text :role, limit: 100,
        null: false
      t.text :content, limit: 16384,
        null: true
      t.text :async_errors, array: true, null: false, default: []

      t.index [:user_id, :project_id, :created_at],
        name: :index_ci_editor_ai_messages_on_user_project_and_created_at

      t.index :project_id,
        name: :index_ci_editor_ai_messages_project_id

      t.index :created_at,
        name: :index_ci_editor_ai_messages_created_at
    end
  end
end

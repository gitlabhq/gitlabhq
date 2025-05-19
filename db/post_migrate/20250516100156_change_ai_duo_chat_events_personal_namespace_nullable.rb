# frozen_string_literal: true

class ChangeAiDuoChatEventsPersonalNamespaceNullable < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def up
    change_column_null :ai_duo_chat_events, :personal_namespace_id, true
  end

  def down
    change_column_null :ai_duo_chat_events, :personal_namespace_id, false
  end
end

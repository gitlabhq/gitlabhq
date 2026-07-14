# frozen_string_literal: true

class DropAiDuoChatEventsTable < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def up
    drop_table :ai_duo_chat_events, if_exists: true
  end

  def down
    # no-op
  end
end

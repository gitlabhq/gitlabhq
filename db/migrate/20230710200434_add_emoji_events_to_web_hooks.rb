# frozen_string_literal: true

class AddEmojiEventsToWebHooks < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :web_hooks, :emoji_events, :boolean, null: false, default: false
  end
end

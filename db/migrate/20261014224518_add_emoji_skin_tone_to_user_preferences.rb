# frozen_string_literal: true

class AddEmojiSkinToneToUserPreferences < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  def change
    add_column :user_preferences, :emoji_skin_tone, :smallint, default: 0, null: false
  end
end

class RenameEmojiAwardToAwardEmoji < ActiveRecord::Migration
  def change
    rename_table :emoji_awards, :award_emoji
  end
end

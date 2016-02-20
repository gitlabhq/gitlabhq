class ConvertAwardNoteToEmojiAward < ActiveRecord::Migration
  def up
    execute "INSERT INTO emoji_awards (awardable_type, awardable_id, user_id, name, created_at, updated_at) (SELECT noteable_type, noteable_id, author_id, note, created_at, updated_at FROM notes WHERE is_award = true)"
  end

  def down
    # TODO
  end
end

# rubocop:disable all
class ConvertAwardNoteToEmojiAward < ActiveRecord::Migration
  def change
    def up
      execute "INSERT INTO award_emoji (awardable_type, awardable_id, user_id, name, created_at, updated_at) (SELECT noteable_type, noteable_id, author_id, note, created_at, updated_at FROM notes WHERE is_award = true)"

      execute "DELETE FROM notes WHERE is_award = true"
    end
  end
end

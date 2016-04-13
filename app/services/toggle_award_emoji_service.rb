require_relative 'base_service'

class ToggleAwardEmojiService < BaseService
  # For an award emoji being posted we should:
  # - Mark the TODO as done for this issuable (skip on snippets)
  # - Save the award emoji
  def execute(awardable, emoji)
    todoable = to_todoable(awardable)
    todo_service.new_award_emoji(todoable, current_user) if todoable

    # Needed if a note is posted as :+1:
    emoji = emoji_award_name(emoji) if emoji.start_with? ':'
    awardable.toggle_award_emoji(emoji, current_user)
  end

  private

  def emoji_award_name(emoji)
    original_name = emoji.match(Banzai::Filter::EmojiFilter.emoji_pattern)[1]
    Gitlab::AwardEmoji.normalize_emoji_name(original_name)
  end

  def to_todoable(awardable)
    case awardable
    when Note
      awardable.noteable
    when Issuable
      awardable
    when Snippet
      nil
    end
  end
end

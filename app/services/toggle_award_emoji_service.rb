require_relative 'base_service'

class ToggleAwardEmojiService < BaseService
  # For an award emoji being posted we should:
  # - Mark the TODO as done for this issuable (skip on snippets)
  # - Save the award emoji
  def execute(awardable, emoji)
    todo_service.new_award_emoji(awardable, current_user)

    # Needed if its posted as a note containing only :+1:
    emoji = award_emoji_name(emoji) if emoji.start_with? ':'
    awardable.toggle_award_emoji(emoji, current_user)
  end

  private

  def award_emoji_name(emoji)
    original_name = emoji.match(Banzai::Filter::EmojiFilter.emoji_pattern)[1]
    Gitlab::AwardEmoji.normalize_emoji_name(original_name)
  end
end

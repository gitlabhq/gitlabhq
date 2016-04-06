require_relative 'base_service'

class CreateEmojiAwardService < BaseService
  # For an award emoji being posted we should:
  # - Mark the TODO as done for this issuable (skip on snippets)
  # - Save the award emoji
  def execute(awardable, item)
    issuable = to_issuable(awardable)
    todo_service.award_emoji(issuable, current_user) if issuable

    awardable.toggle_emoji_award(item, current_user)
  end

  private

  def to_issuable(awardable)
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

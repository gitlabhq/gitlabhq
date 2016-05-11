require_relative 'base_service'

class ToggleAwardEmojiService < BaseService
  def execute(awardable, emoji)
    todo_service.new_award_emoji(awardable, current_user)

    awardable.toggle_award_emoji(emoji, current_user)
  end
end

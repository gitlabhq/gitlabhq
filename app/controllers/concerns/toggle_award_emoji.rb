module ToggleAwardEmoji
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!, only: [:toggle_award_emoji]
  end

  def toggle_award_emoji
    name = params.require(:name)

    if awardable.user_can_award?(current_user, name)
      awardable.toggle_award_emoji(name, current_user)

      todoable = to_todoable(awardable)
      TodoService.new.new_award_emoji(todoable, current_user) if todoable

      render json: { ok: true }
    else
      render json: { ok: false }
    end
  end

  private

  def to_todoable(awardable)
    case awardable
    when Note
      awardable.noteable
    when MergeRequest, Issue
      awardable
    when Snippet
      nil
    end
  end

  def awardable
    raise NotImplementedError
  end
end

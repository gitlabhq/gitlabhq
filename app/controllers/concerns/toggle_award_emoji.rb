module ToggleAwardEmoji
  extend ActiveSupport::Concern

  def toggle_award_emoji
    authenticate_user!
    name = params.require(:name)

    if awardable.user_can_award?(current_user)
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
      # we don't create todos for personal snippet comments for now
      awardable.for_personal_snippet? ? nil : awardable.noteable
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

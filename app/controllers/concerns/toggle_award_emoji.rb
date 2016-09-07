module ToggleAwardEmoji
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!, only: [:toggle_award_emoji]
  end

  def toggle_award_emoji
    name = params.require(:name)

    if awardable.user_can_award?(current_user, name)
      awardable.toggle_award_emoji(name, current_user)
      TodoService.new.new_award_emoji(to_todoable(awardable), current_user)

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
    else
      awardable
    end
  end

  def awardable
    raise NotImplementedError
  end
end

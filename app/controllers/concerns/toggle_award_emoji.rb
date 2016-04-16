module ToggleAwardEmoji
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!, only: [:toggle_award_emoji]
  end

  def toggle_award_emoji
    name = params.require(:name)
    awardable.toggle_award_emoji(name, current_user)

    render json: { ok: true }
  end

  private

  def awardable
    raise NotImplementedError
  end
end

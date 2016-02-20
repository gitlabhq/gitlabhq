module ToggleEmojiAward
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!, only: [:toggle_emoji_award]
  end

  def toggle_emoji_award
    name = params.require(:name)
    awardable.toggle_emoji_award(name, current_user)

    render json: { ok: true }
  end

  private

  def awardable
    raise NotImplementedError
  end
end

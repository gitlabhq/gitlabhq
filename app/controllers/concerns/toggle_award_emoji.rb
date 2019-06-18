# frozen_string_literal: true

module ToggleAwardEmoji
  extend ActiveSupport::Concern

  def toggle_award_emoji
    authenticate_user!
    name = params.require(:name)

    service = AwardEmojis::ToggleService.new(awardable, name, current_user).execute

    if service[:status] == :success
      render json: { ok: true }
    else
      render json: { ok: false }
    end
  end

  private

  def awardable
    raise NotImplementedError
  end
end

# frozen_string_literal: true

module Achievements
  class AwardedAchievementsController < ApplicationController
    include Gitlab::Utils::StrongMemoize

    skip_before_action :authenticate_user!

    feature_category :user_profile
    urgency :low

    def accept
      return render_invalid_link unless user_achievement

      return unless request.post?
      return render_404 if current_user && !recipient_user?
      return render_invalid_link unless recipient_user? || params.permit(:force)[:force]

      accept_and_redirect
    end

    private

    def user_achievement
      Achievements::UserAchievement.find_signed(params.permit(:id)[:id], purpose: :achievement_action)
    end
    strong_memoize_attr :user_achievement

    def recipient_user?
      current_user && current_user == user_achievement.user
    end

    def accept_and_redirect
      user_achievement.update!(show_on_profile: true)

      flash[:success] = _("You have accepted the achievement. It will now appear on your profile.")

      redirect_after_action
    end

    def redirect_after_action
      if current_user
        redirect_to user_path(current_user)
      else
        redirect_to new_user_session_path
      end
    end

    def render_invalid_link
      render template: "errors/expired_sent_notification", formats: :html, layout: "errors", status: :not_found
    end
  end
end

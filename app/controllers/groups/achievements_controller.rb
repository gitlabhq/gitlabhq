# frozen_string_literal: true

module Groups
  class AchievementsController < Groups::ApplicationController
    feature_category :user_profile
    urgency :low

    before_action :authorize_read_achievement!

    def new
      render action: "index"
    end

    private

    def authorize_read_achievement!
      render_404 unless can?(current_user, :read_achievement, group)
    end
  end
end

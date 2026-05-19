# frozen_string_literal: true

module Groups
  class AchievementsController < Groups::ApplicationController
    feature_category :user_profile
    urgency :low

    before_action :authorize_read_achievement!
    before_action :authorize_admin_achievement!, only: [:new, :edit]

    def new
      render action: "index"
    end

    def edit
      render action: "index"
    end

    private

    def authorize_read_achievement!
      render_404 unless can?(current_user, :read_achievement, group)
    end

    def authorize_admin_achievement!
      render_404 unless can?(current_user, :admin_achievement, group)
    end
  end
end

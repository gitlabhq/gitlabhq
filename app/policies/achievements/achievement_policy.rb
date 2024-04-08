# frozen_string_literal: true

module Achievements
  class AchievementPolicy < ::BasePolicy
    delegate { @subject.namespace }

    condition(:achievement_recipient, scope: :subject) do
      @user && @user.user_achievements.any? { |user_achievement| user_achievement.achievement_id == @subject.id }
    end

    rule { achievement_recipient }.policy do
      enable :read_achievement
    end
  end
end

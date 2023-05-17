# frozen_string_literal: true

module Achievements
  class UserAchievementPolicy < ::BasePolicy
    delegate { @subject.achievement.namespace }
    delegate { @subject.user }

    rule { can?(:read_user_profile) | can?(:admin_achievement) }.enable :read_user_achievement

    rule { ~can?(:read_achievement) }.prevent :read_user_achievement
  end
end

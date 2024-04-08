# frozen_string_literal: true

module Achievements
  class UserAchievementPolicy < ::BasePolicy
    delegate { @subject.achievement }
    delegate { @subject.achievement.namespace }
    delegate { @subject.user }

    condition(:user_is_recipient) { @subject.user == @user }

    rule { can?(:read_user_profile) | can?(:admin_achievement) }.enable :read_user_achievement

    rule { user_is_recipient }.enable :update_owned_user_achievement

    rule { can?(:update_owned_user_achievement) }.enable :update_user_achievement

    rule { ~can?(:read_achievement) }.policy do
      prevent :read_user_achievement
      prevent :update_user_achievement
    end
  end
end

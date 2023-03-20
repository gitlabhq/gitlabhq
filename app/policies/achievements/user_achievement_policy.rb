# frozen_string_literal: true

module Achievements
  class UserAchievementPolicy < ::BasePolicy
    delegate { @subject.achievement.namespace }
  end
end

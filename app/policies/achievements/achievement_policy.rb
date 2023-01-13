# frozen_string_literal: true

module Achievements
  class AchievementPolicy < ::BasePolicy
    delegate { @subject.namespace }
  end
end

# frozen_string_literal: true

module Achievements
  class UserAchievement < ApplicationRecord
    belongs_to :achievement, inverse_of: :user_achievements, optional: false
    belongs_to :user, inverse_of: :user_achievements, optional: false

    belongs_to :awarded_by_user,
                class_name: 'User',
                inverse_of: :awarded_user_achievements,
                optional: true
    belongs_to :revoked_by_user,
                class_name: 'User',
                inverse_of: :revoked_user_achievements,
                optional: true
  end
end

# frozen_string_literal: true

module Achievements
  class DestroyUserAchievementService
    attr_reader :current_user, :user_achievement

    def initialize(current_user, user_achievement)
      @current_user = current_user
      @user_achievement = user_achievement
    end

    def execute
      return error_no_permissions unless allowed?

      user_achievement.delete
      ServiceResponse.success(payload: user_achievement)
    end

    private

    def allowed?
      current_user&.can?(:destroy_user_achievement, user_achievement)
    end

    def error_no_permissions
      error('You have insufficient permissions to delete this user achievement')
    end

    def error(message)
      ServiceResponse.error(message: Array(message))
    end
  end
end

# frozen_string_literal: true

module Achievements
  class DestroyService
    attr_reader :current_user, :achievement

    def initialize(current_user, achievement)
      @current_user = current_user
      @achievement = achievement
    end

    def execute
      return error_no_permissions unless allowed?

      achievement.delete
      ServiceResponse.success(payload: achievement)
    end

    private

    def allowed?
      current_user&.can?(:admin_achievement, achievement)
    end

    def error_no_permissions
      error('You have insufficient permissions to delete this achievement')
    end

    def error(message)
      ServiceResponse.error(message: Array(message))
    end
  end
end

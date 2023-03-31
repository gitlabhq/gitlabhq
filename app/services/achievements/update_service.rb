# frozen_string_literal: true

module Achievements
  class UpdateService
    attr_reader :current_user, :achievement, :params

    def initialize(current_user, achievement, params)
      @current_user = current_user
      @achievement = achievement
      @params = params
    end

    def execute
      return error_no_permissions unless allowed?

      if achievement.update(params)
        ServiceResponse.success(payload: achievement)
      else
        error_updating
      end
    end

    private

    def allowed?
      current_user&.can?(:admin_achievement, achievement)
    end

    def error_no_permissions
      error('You have insufficient permission to update this achievement')
    end

    def error(message)
      ServiceResponse.error(payload: achievement, message: Array(message))
    end

    def error_updating
      error(achievement&.errors&.full_messages || 'Failed to update achievement')
    end
  end
end

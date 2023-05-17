# frozen_string_literal: true

module Achievements
  class RevokeService
    attr_reader :current_user, :user_achievement

    def initialize(current_user, user_achievement)
      @current_user = current_user
      @user_achievement = user_achievement
    end

    def execute
      return error_no_permissions unless allowed?(user_achievement.achievement)
      return error_already_revoked if user_achievement.revoked?

      user_achievement.assign_attributes({
        revoked_by_user_id: current_user.id,
        revoked_at: Time.zone.now
      })
      return error_awarding unless user_achievement.save

      ServiceResponse.success(payload: user_achievement)
    end

    private

    def allowed?(achievement)
      current_user&.can?(:award_achievement, achievement)
    end

    def error_no_permissions
      error('You have insufficient permissions to revoke this achievement')
    end

    def error_already_revoked
      error('This achievement has already been revoked')
    end

    def error_awarding
      error(user_achievement&.errors&.full_messages || 'Failed to revoke achievement')
    end

    def error(message)
      ServiceResponse.error(message: Array(message))
    end
  end
end

# frozen_string_literal: true

module Achievements
  class AwardService
    attr_reader :current_user, :achievement_id, :recipient_id

    def initialize(current_user, achievement_id, recipient_id)
      @current_user = current_user
      @achievement_id = achievement_id
      @recipient_id = recipient_id
    end

    def execute
      achievement = Achievements::Achievement.find(achievement_id)
      return error_no_permissions unless allowed?(achievement)

      recipient = User.find(recipient_id)

      user_achievement = Achievements::UserAchievement.create(
        achievement: achievement,
        user: recipient,
        awarded_by_user: current_user)
      return error_awarding(user_achievement) unless user_achievement.persisted?

      NotificationService.new.new_achievement_email(recipient, achievement).deliver_later
      ServiceResponse.success(payload: user_achievement)
    rescue ActiveRecord::RecordNotFound => e
      error(e.message)
    end

    private

    def allowed?(achievement)
      current_user&.can?(:award_achievement, achievement)
    end

    def error_no_permissions
      error('You have insufficient permissions to award this achievement')
    end

    def error_awarding(user_achievement)
      error(user_achievement&.errors&.full_messages || 'Failed to award achievement')
    end

    def error(message)
      ServiceResponse.error(message: Array(message))
    end
  end
end

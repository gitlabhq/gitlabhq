# frozen_string_literal: true

module Achievements
  class UpdateUserAchievementPrioritiesService
    attr_reader :current_user, :user_achievements

    def initialize(current_user, user_achievements)
      @current_user = current_user
      @user_achievements = user_achievements
    end

    def execute
      return error_no_permissions unless allowed?

      prioritized_user_achievements_map = Hash[user_achievements.map.with_index { |ua, idx| [ua.id, idx] }]

      user_achievements_priorities_mapping = current_user.user_achievements.each_with_object({}) do |ua, result|
        next if ua.priority.nil? && !prioritized_user_achievements_map.key?(ua.id)

        result[ua] = { priority: prioritized_user_achievements_map.fetch(ua.id, nil) }
      end

      return ServiceResponse.success(payload: []) if user_achievements_priorities_mapping.empty?

      ::Gitlab::Database::BulkUpdate.execute(%i[priority], user_achievements_priorities_mapping)

      ServiceResponse.success(payload: user_achievements_priorities_mapping.keys.map(&:reload))
    end

    private

    def allowed?
      user_achievements.all? { |user_achievement| current_user&.can?(:update_owned_user_achievement, user_achievement) }
    end

    def error(message)
      ServiceResponse.error(payload: user_achievements, message: Array(message))
    end

    def error_no_permissions
      error("You can't update at least one of the given user achievements.")
    end
  end
end

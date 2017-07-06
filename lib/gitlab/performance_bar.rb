module Gitlab
  module PerformanceBar
    include Gitlab::CurrentSettings

    ALLOWED_USER_IDS_KEY = 'performance_bar_allowed_user_ids'.freeze
    # The time (in seconds) after which a set of allowed user IDs is expired
    # automatically.
    ALLOWED_USER_IDS_TIME_TO_LIVE = 10.minutes

    def self.enabled?(current_user = nil)
      Feature.enabled?(:performance_bar, current_user)
    end

    def self.allowed_user?(user)
      return false unless allowed_group_id

      allowed_user_ids.include?(user.id)
    end

    def self.allowed_group_id
      current_application_settings.performance_bar_allowed_group_id
    end

    def self.allowed_user_ids
      Rails.cache.fetch(ALLOWED_USER_IDS_KEY, expires_in: ALLOWED_USER_IDS_TIME_TO_LIVE) do
        group = Group.find_by_id(allowed_group_id)

        if group
          GroupMembersFinder.new(group).execute.pluck(:user_id)
        else
          []
        end
      end
    end

    def self.expire_allowed_user_ids_cache
      Rails.cache.delete(ALLOWED_USER_IDS_KEY)
    end
  end
end

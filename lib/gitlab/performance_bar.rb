module Gitlab
  module PerformanceBar
    ALLOWED_USER_IDS_KEY = 'performance_bar_allowed_user_ids:v2'.freeze
    EXPIRY_TIME = 5.minutes

    def self.enabled?(user = nil)
      return true if Rails.env.development?
      return false unless user && allowed_group_id

      allowed_user_ids.include?(user.id)
    end

    def self.allowed_group_id
      Gitlab::CurrentSettings.performance_bar_allowed_group_id
    end

    def self.allowed_user_ids
      Rails.cache.fetch(ALLOWED_USER_IDS_KEY, expires_in: EXPIRY_TIME) do
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

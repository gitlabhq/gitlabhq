module Gitlab
  module PerformanceBar
    ALLOWED_USER_IDS_KEY = 'performance_bar_allowed_user_ids'.freeze
    # The time (in seconds) after which a set of allowed user IDs is expired
    # automatically.
    ALLOWED_USER_IDS_TIME_TO_LIVE = 10.minutes

    def self.enabled?(current_user = nil)
      Feature.enabled?(:gitlab_performance_bar, current_user)
    end

    def self.allowed_user?(user)
      return false unless allowed_group_name

      allowed_user_ids.include?(user.id)
    end

    def self.allowed_group_name
      Gitlab.config.performance_bar.allowed_group
    end

    def self.allowed_user_ids
      Rails.cache.fetch(cache_key, expires_in: ALLOWED_USER_IDS_TIME_TO_LIVE) do
        group = Group.find_by_full_path(allowed_group_name)

        if group
          GroupMembersFinder.new(group).execute.pluck(:user_id)
        else
          []
        end
      end
    end

    def self.cache_key
      "#{ALLOWED_USER_IDS_KEY}:#{allowed_group_name}"
    end
  end
end

module Gitlab
  module PerformanceBar
    ALLOWED_USER_IDS_KEY = 'performance_bar_allowed_user_ids'.freeze
    # The time (in seconds) after which a set of allowed user IDs is expired
    # automatically.
    ALLOWED_USER_IDS_TIME_TO_LIVE = 10.minutes.to_i

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
      Gitlab::Redis.with do |redis|
        if redis.exists(cache_key)
          redis.smembers(cache_key).map(&:to_i)
        else
          group = Group.find_by_full_path(allowed_group_name)
          # Redis#sadd doesn't accept an empty array, but we still want to use
          # Redis to let us know that no users are allowed, so we set the
          # array to [-1] in this case.
          user_ids =
            if group
              GroupMembersFinder.new(group).execute
                .pluck(:user_id).presence || [-1]
            else
              [-1]
            end

          redis.multi do
            redis.sadd(cache_key, user_ids)
            redis.expire(cache_key, ALLOWED_USER_IDS_TIME_TO_LIVE)
          end

          user_ids
        end
      end
    end

    def self.cache_key
      "#{ALLOWED_USER_IDS_KEY}:#{allowed_group_name}"
    end
  end
end

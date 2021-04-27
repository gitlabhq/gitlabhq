# frozen_string_literal: true

module Gitlab
  module PerformanceBar
    ALLOWED_USER_IDS_KEY = 'performance_bar_allowed_user_ids:v2'
    EXPIRY_TIME_L1_CACHE = 1.minute
    EXPIRY_TIME_L2_CACHE = 5.minutes

    def self.enabled_for_request?
      !Gitlab::SafeRequestStore[:capturing_flamegraph] && Gitlab::SafeRequestStore[:peek_enabled]
    end

    def self.allowed_for_user?(user = nil)
      return true if Rails.env.development?
      return true if user&.admin?
      return false unless user && allowed_group_id

      allowed_user_ids.include?(user.id)
    end

    def self.allowed_group_id
      Gitlab::CurrentSettings.performance_bar_allowed_group_id
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def self.allowed_user_ids
      l1_cache_backend.fetch(ALLOWED_USER_IDS_KEY, expires_in: EXPIRY_TIME_L1_CACHE) do
        l2_cache_backend.fetch(ALLOWED_USER_IDS_KEY, expires_in: EXPIRY_TIME_L2_CACHE) do
          group = Group.find_by_id(allowed_group_id)

          if group
            GroupMembersFinder.new(group).execute.pluck(:user_id)
          else
            []
          end
        end
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def self.expire_allowed_user_ids_cache
      l1_cache_backend.delete(ALLOWED_USER_IDS_KEY)
      l2_cache_backend.delete(ALLOWED_USER_IDS_KEY)
    end

    def self.l1_cache_backend
      Gitlab::ProcessMemoryCache.cache_backend
    end

    def self.l2_cache_backend
      Rails.cache
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Chat
    CACHE_TTL = 1.hour.to_i
    AVAILABLE_CACHE_KEY = :gitlab_chat_available

    # Returns `true` if Chatops is available for the current instance.
    def self.available?
      # We anticipate this code to be called rather frequently, especially on
      # large instances such as GitLab.com. To reduce database load we cache the
      # output for a while.
      Rails.cache.fetch(AVAILABLE_CACHE_KEY, expires_in: CACHE_TTL) do
        ::License.feature_available?(:chatops)
      end
    end

    def self.flush_available_cache
      Rails.cache.delete(AVAILABLE_CACHE_KEY)
    end
  end
end

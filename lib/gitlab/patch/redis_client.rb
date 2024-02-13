# frozen_string_literal: true

module Gitlab
  module Patch
    module RedisClient
      # This patch resets the connection error tracker after each call to prevent state leak
      # across calls and requests.
      #
      # The purpose of the tracker is to silence RedisClient::ConnectionErrors during reconnection attempts.
      # More details found in https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/2564#note_1665334335
      def ensure_connected(retryable: true)
        super
      ensure
        Thread.current[:redis_client_error_count] = 0
      end
    end
  end
end

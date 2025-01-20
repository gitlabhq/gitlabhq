# frozen_string_literal: true

module Gitlab
  module Sessions
    class CacheStore < ActionDispatch::Session::CacheStore
      DELIMITER = '-'

      attr_reader :session_cookie_token_prefix

      def initialize(app, options = {})
        super

        @session_cookie_token_prefix = options.fetch(:session_cookie_token_prefix, "") || ""
      end

      def generate_sid
        delimiter = session_cookie_token_prefix.empty? ? '' : DELIMITER
        Rack::Session::SessionId.new(session_cookie_token_prefix + delimiter + super.public_id)
      end

      private

      # ActionDispatch::Session::CacheStore (superclass) prepends
      # hardcoded "_session_id:" to the cache key which doesn't match
      # the previous implementation of Gitlab::Sessions::RedisStore.
      def cache_key(id)
        id
      end
    end
  end
end

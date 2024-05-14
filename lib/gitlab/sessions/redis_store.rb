# frozen_string_literal: true

module Gitlab
  module Sessions
    class RedisStore < ActionDispatch::Session::RedisStore
      attr_reader :session_cookie_token_prefix

      def initialize(app, options = {})
        super

        @session_cookie_token_prefix = options.fetch(:session_cookie_token_prefix, "") || ""
      end

      def generate_sid
        Rack::Session::SessionId.new(session_cookie_token_prefix + super.public_id)
      end
    end
  end
end

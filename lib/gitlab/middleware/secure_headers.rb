# frozen_string_literal: true

module Gitlab
  module Middleware
    class SecureHeaders
      def initialize(app)
        @app = app
      end

      def call(env)
        status, headers, body = @app.call(env)

        # Remove NEL policy from the policy cache by setting max_age to 0.
        # https://w3c.github.io/network-error-logging/#the-max_age-member
        # https://w3c.github.io/network-error-logging/#example-2
        headers['NEL'] = '{"max_age": 0}'

        [status, headers, body]
      end
    end
  end
end

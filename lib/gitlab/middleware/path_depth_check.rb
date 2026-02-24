# frozen_string_literal: true

module Gitlab
  module Middleware
    # Protect against ReDoS via deep URL paths.
    #
    # Limiting path depth in Gitlab::PathRegex.full_namespace_route_regex was considered
    # and tested, but was insufficient because Rails routing evaluates multiple
    # patterns before matching. Rejecting deep paths in middleware avoids the
    # routing overhead entirely.
    class PathDepthCheck
      # Namespace depth (20) + project (1) + route segments + file path depth + buffer
      MAX_PATH_SEGMENTS = 50
      REJECTION_RESPONSE = [
        414,
        { 'Content-Type' => 'text/plain' },
        ['Request-URI Too Long: path exceeds maximum depth']
      ].freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        path_segment_count = env['PATH_INFO'].to_s.count('/')

        if path_segment_count > MAX_PATH_SEGMENTS
          log_rejection(env, path_segment_count)
          return REJECTION_RESPONSE
        end

        @app.call(env)
      end

      private

      def log_rejection(env, path_segment_count)
        Gitlab::AppLogger.warn(
          message: 'Path depth limit exceeded',
          class_name: self.class.name,
          path_segment_count: path_segment_count,
          remote_ip: env['REMOTE_ADDR']
        )
      end
    end
  end
end

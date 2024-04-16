# frozen_string_literal: true

module Gitlab
  module Middleware
    class StripCookies
      attr_reader :app, :paths

      # Initializes the middleware.
      #
      # @param app [Rack application] The Rack application.
      # @param options [Hash] The options to customize the middleware behavior.
      # @option options [Array<Regexp>] :paths The regular expressions to match
      #   against the path when cookies should be deleted.
      def initialize(app, options = {})
        @app = app
        @paths = Array(options[:paths])
      end

      def call(env)
        # Extract the path from the request
        path = Rack::Request.new(env).path

        # Check if the request path is in the list of paths to be stripped
        strip_out = paths.any? { |regex| regex.match?(path) }

        # If cookies are to be stripped, delete the HTTP_COOKIE from the request environment
        env.delete("HTTP_COOKIE") if strip_out

        status, headers, body = @app.call(env)

        # If cookies are to be stripped, delete the Set-Cookie header from the response
        headers.delete("Set-Cookie") if strip_out

        # Return the response (status, headers, body) to the next middleware or the web server
        [status, headers, body]
      end
    end
  end
end

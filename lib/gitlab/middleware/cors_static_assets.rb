# frozen_string_literal: true

module Gitlab
  module Middleware
    class CorsStaticAssets
      def initialize(app)
        @app = app
      end

      def call(env)
        # This middleware handles GET, HEAD, and OPTIONS requests to get CORS headers for static assets.
        # The OPTIONS HTTP request is sent by Workhorse when it serves a static asset and
        # the static asset route does not exist in Rails. For this type of request, the middleware
        # returns early.
        # This middleware also handles GET requests although this type request only happen in
        # development or test environments when the sprockets pipeline is enabled.
        request = ActionDispatch::Request.new(env)

        return @app.call(env) unless handles_request?(request)

        headers = get_cors_headers(request)

        return [204, headers, []] if request.method == 'OPTIONS'

        status, base_headers, body = @app.call(env)

        headers.merge!(base_headers)

        [status, headers, body]
      end

      private

      def handles_request?(request)
        %w[OPTIONS GET HEAD].include?(request.method) && request.path.start_with?('/assets/')
      end

      def get_cors_headers(request)
        origin_header = request.headers['Origin']
        match = ::WebIde::ExtensionMarketplace.origin_matches_extension_host_regexp.match(origin_header)
        base_domain = ::WebIde::ExtensionMarketplace.extension_host_domain

        if match
          {
            'Access-Control-Allow-Origin' => build_allowed_origin_url(match[1], base_domain),
            'Access-Control-Allow-Methods' => 'GET, HEAD, OPTIONS',
            'Vary' => 'Origin'
          }
        else
          {}
        end
      end

      def build_allowed_origin_url(allowed_subdomain, base_domain)
        "https://#{allowed_subdomain}.#{base_domain}"
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Middleware
    class JsRoutes
      DIGEST_FILE_PATH = Rails.root.join('tmp/js_routes_hash')

      def initialize(app)
        @app = app
      end

      def call(env)
        generate!(env)
        @app.call(env)
      end

      private

      def read_digest
        return unless File.exist?(DIGEST_FILE_PATH)

        File.read(DIGEST_FILE_PATH).strip
      end

      def update_digest(new_digest)
        File.write(DIGEST_FILE_PATH, new_digest)
      end

      def generate_digest
        route_specs = Rails.application.routes.routes.map do |route|
          route.path.spec.to_s
        end.uniq.sort.join("\n")

        Digest::SHA256.hexdigest(route_specs)
      end

      def html_get_request?(env)
        return false unless env

        method = env['REQUEST_METHOD']
        accept = env['HTTP_ACCEPT'].to_s

        method == 'GET' && accept.include?('text/html')
      end

      def generate!(env)
        # Only generate routes for GET requests to HTML pages
        return unless html_get_request?(env)

        new_digest = generate_digest

        # Only generate routes if the digest has changed
        return if new_digest == read_digest

        Gitlab::JsRoutes.generate!

        # Update digest
        update_digest(new_digest)
      end
    end
  end
end

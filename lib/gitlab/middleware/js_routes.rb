# frozen_string_literal: true

module Gitlab
  module Middleware
    class JsRoutes < ::JsRoutes::Middleware
      extend ::Gitlab::Utils::Override

      DIGEST_FILE_PATH = Rails.root.join('tmp/js_routes_hash')

      def initialize(app)
        super
        @digest = read_digest
      end

      def call(env)
        @current_env = env

        response = super

        write_digest(@digest)

        response
      end

      protected

      # Override `regenerate` method in parent class so we can customize generation of JavaScript path helpers
      # Based on advanced setup documentation in https://github.com/railsware/js-routes?tab=readme-ov-file#advanced-setup
      override :regenerate
      def regenerate(*)
        return if skip_regeneration?

        Gitlab::JsRoutes.generate!
      end

      # Override `fetch_digest` method to improve caching.
      # The parent class only caches based on changes in `config/routes.rb` and does not persist between Rails restarts.
      # This method caches based on all route files and persists between Rails restarts.
      override :fetch_digest
      def fetch_digest(*)
        route_specs = Rails.application.routes.routes.map do |route|
          "#{route.verb} #{route.path.spec}"
        end.sort.join("\n")

        Digest::SHA256.hexdigest(route_specs)
      end

      private

      def read_digest
        return unless File.exist?(DIGEST_FILE_PATH)

        File.read(DIGEST_FILE_PATH).strip
      end

      def write_digest(digest)
        File.write(DIGEST_FILE_PATH, digest)
      end

      def skip_regeneration?
        return false unless @current_env

        # Only regenerate for GET requests to HTML pages
        method = @current_env['REQUEST_METHOD']
        accept = @current_env['HTTP_ACCEPT'].to_s

        method != 'GET' || accept.exclude?('text/html')
      end
    end
  end
end

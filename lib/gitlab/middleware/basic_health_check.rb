# frozen_string_literal: true

# This middleware provides a health check that does not hit the database. Its purpose
# is to notify the prober that the application server is handling requests, but a 200
# response does not signify that the database or other services are ready.
#
# See https://thisdata.com/blog/making-a-rails-health-check-that-doesnt-hit-the-database/ for
# more details.

module Gitlab
  module Middleware
    class BasicHealthCheck
      # This can't be frozen because Rails::Rack::Logger wraps the body
      # rubocop:disable Style/MutableConstant
      OK_RESPONSE = [200, { 'Content-Type' => 'text/plain' }, ["GitLab OK"]]
      EMPTY_RESPONSE = [404, { 'Content-Type' => 'text/plain' }, [""]]
      # rubocop:enable Style/MutableConstant
      HEALTH_PATH = '/-/health'

      def initialize(app)
        @app = app
      end

      def call(env)
        return @app.call(env) unless env['PATH_INFO'] == HEALTH_PATH

        # We should be using ActionDispatch::Request instead of
        # Rack::Request to be consistent with Rails, but due to a Rails
        # bug described in
        # https://gitlab.com/gitlab-org/gitlab-foss/issues/58573#note_149799010
        # hosts behind a load balancer will only see 127.0.0.1 for the
        # load balancer's IP.
        request = Rack::Request.new(env)

        return OK_RESPONSE if client_ip_whitelisted?(request)

        EMPTY_RESPONSE
      end

      def client_ip_whitelisted?(request)
        ip_whitelist.any? { |e| e.include?(request.ip) }
      end

      def ip_whitelist
        @ip_whitelist ||= Settings.monitoring.ip_whitelist.map(&IPAddr.method(:new))
      end
    end
  end
end

# frozen_string_literal: true

# This middleware provides a health check that does not hit the database. Its purpose
# is to notify the prober that the application server is handling requests, but a 200
# response does not signify that the database or other services are ready.
#
# See https://thisdata.com/blog/making-a-rails-health-check-that-doesnt-hit-the-database/ for
# more details.

module Gitlab
  module Middleware
    class LivenessHealthCheck
      # This can't be frozen because Rails::Rack::Logger wraps the body
      # rubocop:disable Style/MutableConstant
      OK_RESPONSE = [200, { 'Content-Type' => 'text/plain' }, ["GitLab is alive"]]
      EMPTY_RESPONSE = [404, { 'Content-Type' => 'text/plain' }, [""]]
      # rubocop:enable Style/MutableConstant
      LIVENESS_PATH = '/-/liveness'

      def initialize(app)
        @app = app
      end

      def call(env)
        return @app.call(env) unless env['PATH_INFO'] == LIVENESS_PATH

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

module Gitlab
  module Metrics
    class ConnectionRackMiddleware
      def initialize(app)
        @app = app
      end

      def self.rack_request_count
        @rack_request_count ||= Gitlab::Metrics.counter(:rack_request, 'Rack request count')
      end

      def self.rack_response_count
        @rack_response_count ||= Gitlab::Metrics.counter(:rack_response, 'Rack response count')
      end

      def self.rack_uncaught_errors_count
        @rack_uncaught_errors_count ||= Gitlab::Metrics.counter(:rack_uncaught_errors, 'Rack connections handling uncaught errors count')
      end

      def self.rack_execution_time
        @rack_execution_time ||= Gitlab::Metrics.histogram(:rack_execution_time, 'Rack connection handling execution time',
                                                           {}, [0.05, 0.1, 0.25, 0.5, 0.7, 1, 1.5, 2, 2.5, 3, 5, 7, 10])
      end

      def call(env)
        method = env['REQUEST_METHOD'].downcase
        started = Time.now.to_f
        begin
          ConnectionRackMiddleware.rack_request_count.increment(method: method)

          status, headers, body = @app.call(env)

          ConnectionRackMiddleware.rack_response_count.increment(method: method, status: status)
          [status, headers, body]
        rescue
          ConnectionRackMiddleware.rack_uncaught_errors_count.increment
          raise
        ensure
          elapsed = Time.now.to_f - started
          ConnectionRackMiddleware.rack_execution_time.observe({}, elapsed)
        end
      end
    end
  end
end

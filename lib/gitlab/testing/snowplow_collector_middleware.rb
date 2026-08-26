# frozen_string_literal: true

module Gitlab
  module Testing
    # Answers the collector endpoint the Snowplow browser tracker posts to, so frontend
    # events reach SnowplowEvents instead of leaving the test process. Only specs tagged
    # :capture_snowplow_events point the tracker here; see spec/support/capture_snowplow_events.rb.
    class SnowplowCollectorMiddleware
      COLLECTOR_PATH = '/com.snowplowanalytics.snowplow/tp2'

      def initialize(app)
        @app = app
      end

      def call(env)
        return @app.call(env) unless collector_request?(env)

        payload = ::Gitlab::Json::SafeParser.parse(env['rack.input'].read)
        SnowplowEvents.record(payload&.dig('data') || [])

        [200, { 'Content-Type' => 'text/plain' }, ['ok']]
      end

      private

      def collector_request?(env)
        env['REQUEST_METHOD'] == 'POST' && env['PATH_INFO'] == COLLECTOR_PATH
      end
    end
  end
end

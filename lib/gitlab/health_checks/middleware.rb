# frozen_string_literal: true

module Gitlab
  module HealthChecks
    class Middleware
      def initialize(app, readiness_probe, liveness_probe)
        @app = app
        @readiness_probe = readiness_probe
        @liveness_probe = liveness_probe
      end

      def call(env)
        case env['PATH_INFO']
        when '/readiness' then render_probe(@readiness_probe)
        when '/liveness' then render_probe(@liveness_probe)
        else @app.call(env)
        end
      end

      private

      def render_probe(probe)
        result = probe.execute

        [
          result.http_status,
          { 'Content-Type' => 'application/json; charset=utf-8' },
          [result.json.to_json]
        ]
      end
    end
  end
end

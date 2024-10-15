# frozen_string_literal: true

module Gitlab
  module Middleware
    class MemoryReport
      def initialize(app)
        @app = app
      end

      def call(env)
        request = ActionDispatch::Request.new(env)

        return @app.call(env) unless rendering_memory_profiler?(request)

        begin
          require 'memory_profiler'

          report = MemoryProfiler.report do
            @app.call(env)
          end

          report = report_to_string(report)
          headers = { 'Content-Type' => 'text/plain' }

          [200, headers, [report]]
        rescue StandardError => e
          ::Gitlab::ErrorTracking.track_exception(e)
          [500, { 'Content-Type' => 'text/plain' }, ["Could not generate memory report: #{e}"]]
        end
      end

      private

      def rendering_memory_profiler?(request)
        request.params['performance_bar'] == 'memory' &&
          ::Gitlab::PerformanceBar.allowed_for_user?(request.env['warden']&.user)
      end

      def report_to_string(report)
        io = StringIO.new
        report.pretty_print(io, detailed_report: true, scale_bytes: true, normalize_paths: true)
        io.string
      end
    end
  end
end

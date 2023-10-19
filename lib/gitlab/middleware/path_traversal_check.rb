# frozen_string_literal: true

module Gitlab
  module Middleware
    class PathTraversalCheck
      PATH_TRAVERSAL_MESSAGE = 'Potential path traversal attempt detected'

      def initialize(app)
        @app = app
      end

      def call(env)
        if Feature.enabled?(:check_path_traversal_middleware, Feature.current_request)
          log_params = {}

          execution_time = measure_execution_time do
            check(env, log_params)
          end

          log_params[:duration_ms] = execution_time.round(5) if execution_time

          log(log_params) unless log_params.empty?
        end

        @app.call(env)
      end

      private

      def measure_execution_time(&blk)
        if Feature.enabled?(:log_execution_time_path_traversal_middleware, Feature.current_request)
          Benchmark.ms(&blk)
        else
          yield

          nil
        end
      end

      def check(env, log_params)
        request = ::Rack::Request.new(env)
        fullpath = request.fullpath
        decoded_fullpath = CGI.unescape(fullpath)
        ::Gitlab::PathTraversal.check_path_traversal!(decoded_fullpath, skip_decoding: true)

      rescue ::Gitlab::PathTraversal::PathTraversalAttackError
        log_params[:fullpath] = fullpath
        log_params[:message] = PATH_TRAVERSAL_MESSAGE
      end

      def log(payload)
        Gitlab::AppLogger.warn(
          payload.merge(class_name: self.class.name)
        )
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Middleware
    class PathTraversalCheck
      PATH_TRAVERSAL_MESSAGE = 'Potential path traversal attempt detected'

      EXCLUDED_EXACT_PATHS = %w[/search].freeze
      EXCLUDED_PATH_PREFIXES = %w[/search/].freeze

      EXCLUDED_API_PATHS = %w[/search].freeze
      EXCLUDED_PROJECT_API_PATHS = %w[/search].freeze
      EXCLUDED_GROUP_API_PATHS = %w[/search].freeze

      API_PREFIX = %r{/api/[^/]+}
      API_SUFFIX = %r{(?:\.[^/]+)?}

      EXCLUDED_API_PATHS_REGEX = [
        EXCLUDED_API_PATHS.map do |path|
          %r{\A#{API_PREFIX}#{path}#{API_SUFFIX}\z}
        end.freeze,
        EXCLUDED_PROJECT_API_PATHS.map do |path|
          %r{\A#{API_PREFIX}/projects/[^/]+(?:/-)?#{path}#{API_SUFFIX}\z}
        end.freeze,
        EXCLUDED_GROUP_API_PATHS.map do |path|
          %r{\A#{API_PREFIX}/groups/[^/]+(?:/-)?#{path}#{API_SUFFIX}\z}
        end.freeze
      ].flatten.freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        return @app.call(env) unless Feature.enabled?(:check_path_traversal_middleware, Feature.current_request)

        log_params = {}

        execution_time = measure_execution_time do
          request = ::Rack::Request.new(env.dup)
          check(request, log_params) unless excluded?(request)
        end
        log_params[:duration_ms] = execution_time.round(5) if execution_time

        result = @app.call(env)

        unless log_params.empty?
          log_params[:status] = result.first
          log(log_params)
        end

        result
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

      def check(request, log_params)
        decoded_fullpath = CGI.unescape(request.fullpath)
        ::Gitlab::PathTraversal.check_path_traversal!(decoded_fullpath, skip_decoding: true)
      rescue ::Gitlab::PathTraversal::PathTraversalAttackError
        log_params[:method] = request.request_method
        log_params[:fullpath] = request.fullpath
        log_params[:message] = PATH_TRAVERSAL_MESSAGE
      end

      def excluded?(request)
        path = request.path

        return true if path.in?(EXCLUDED_EXACT_PATHS)
        return true if EXCLUDED_PATH_PREFIXES.any? { |p| path.start_with?(p) }
        return true if EXCLUDED_API_PATHS_REGEX.any? { |r| path.match?(r) }

        false
      end

      def log(payload)
        Gitlab::AppLogger.warn(
          payload.merge(class_name: self.class.name)
        )
      end
    end
  end
end

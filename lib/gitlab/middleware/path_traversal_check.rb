# frozen_string_literal: true

module Gitlab
  module Middleware
    class PathTraversalCheck
      PATH_TRAVERSAL_MESSAGE = 'Potential path traversal attempt detected. Feedback issue: https://gitlab.com/gitlab-org/gitlab/-/issues/520714.'
      # Query param names known to have string parts detected as path traversal even though
      # they are valid genuine requests
      EXCLUDED_QUERY_PARAM_NAMES = %w[
        search
        search_title
        search_query
        term
        name
        filter
        filter_projects
        note
        body
        commit_message
        content
        description
      ].freeze
      NESTED_PARAMETERS_MAX_LEVEL = 5
      REJECT_RESPONSE = [
        Rack::Utils::SYMBOL_TO_STATUS_CODE[:bad_request],
        { 'Content-Type' => 'text/plain' },
        [PATH_TRAVERSAL_MESSAGE]
      ].freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        return @app.call(env) unless Feature.enabled?(:check_path_traversal_middleware, Feature.current_request)

        request = ::ActionDispatch::Request.new(env.dup)
        log_params = {}

        return @app.call(env) unless path_traversal_attempt?(request, log_params)

        log_params[:request_rejected] = true

        # TODO Remove this when https://gitlab.com/gitlab-org/ruby/gems/labkit-ruby/-/issues/41 is implemented
        log_params[:remote_ip] = request.remote_ip

        log(log_params)

        REJECT_RESPONSE
      end

      private

      def path_traversal_attempt?(request, log_params)
        with_duration_metric do |metric_labels|
          original_fullpath = request.filtered_path
          exclude_query_parameters(request)

          decoded_fullpath = CGI.unescape(request.fullpath)

          path_traversal_attempt = Gitlab::PathTraversal.path_traversal?(decoded_fullpath, match_new_line: false)

          metric_labels[:request_rejected] = path_traversal_attempt
          if path_traversal_attempt
            log_params[:method] = request.request_method
            log_params[:fullpath] = original_fullpath
            log_params[:message] = PATH_TRAVERSAL_MESSAGE
          end

          path_traversal_attempt
        end
      end

      def exclude_query_parameters(request)
        query_params = request.GET
        return if query_params.empty?

        cleanup_query_parameters!(query_params)

        request.set_header(Rack::QUERY_STRING, Rack::Utils.build_nested_query(query_params))
      end

      def cleanup_query_parameters!(params, level: 1)
        return params if params.empty? || level > NESTED_PARAMETERS_MAX_LEVEL

        params.except!(*EXCLUDED_QUERY_PARAM_NAMES)
        params.each { |k, v| params[k] = cleanup_query_parameters!(v, level: level + 1) if v.is_a?(Hash) }
      end

      def log(payload)
        ::Gitlab::InstrumentationHelper.add_instrumentation_data(payload)
        Gitlab::AppLogger.warn(payload.merge(class_name: self.class.name))
      end

      def with_duration_metric
        result = nil
        labels = {}

        duration = Benchmark.realtime do
          result = yield(labels)
        end

        ::Gitlab::Instrumentation::Middleware::PathTraversalCheck.duration = duration
        ::Gitlab::Metrics::Middleware::PathTraversalCheck.increment(labels: labels, duration: duration)

        result
      end
    end
  end
end

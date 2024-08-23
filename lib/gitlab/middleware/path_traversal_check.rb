# frozen_string_literal: true

module Gitlab
  module Middleware
    class PathTraversalCheck
      PATH_TRAVERSAL_MESSAGE = 'Potential path traversal attempt detected'
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

      def initialize(app)
        @app = app
      end

      def call(env)
        return @app.call(env) unless Feature.enabled?(:check_path_traversal_middleware, Feature.current_request)

        log_params = {}

        request = ::Rack::Request.new(env.dup)
        check(request, log_params)

        result = @app.call(env)

        unless log_params.empty?
          log_params[:status] = result.first
          log(log_params)
        end

        result
      end

      private

      def check(request, log_params)
        original_fullpath = request.fullpath
        exclude_query_parameters(request)

        decoded_fullpath = CGI.unescape(request.fullpath)

        return unless Gitlab::PathTraversal.path_traversal?(decoded_fullpath, match_new_line: false)

        log_params[:method] = request.request_method
        log_params[:fullpath] = original_fullpath
        log_params[:message] = PATH_TRAVERSAL_MESSAGE
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
        Gitlab::AppLogger.warn(
          payload.merge(class_name: self.class.name)
        )
      end
    end
  end
end

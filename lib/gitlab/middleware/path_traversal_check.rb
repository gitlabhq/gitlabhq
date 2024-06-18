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
        term
        name
        filter
        filter_projects
        note
        body
        commit_message
        content
      ].freeze

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
        exclude_query_parameters(request)

        decoded_fullpath = CGI.unescape(request.fullpath)

        return unless Gitlab::PathTraversal.path_traversal?(decoded_fullpath, match_new_line: false)

        log_params[:method] = request.request_method
        log_params[:fullpath] = request.fullpath
        log_params[:message] = PATH_TRAVERSAL_MESSAGE
      end

      def exclude_query_parameters(request)
        query_params = request.GET
        return if query_params.empty?

        query_params.except!(*EXCLUDED_QUERY_PARAM_NAMES)
        request.set_header(Rack::QUERY_STRING, Rack::Utils.build_nested_query(query_params))
      end

      def log(payload)
        Gitlab::AppLogger.warn(
          payload.merge(class_name: self.class.name)
        )
      end
    end
  end
end

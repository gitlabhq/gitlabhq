# frozen_string_literal: true

module Gitlab
  module Middleware
    class ReadOnly
      class Controller
        DISALLOWED_METHODS = %w(POST PATCH PUT DELETE).freeze
        APPLICATION_JSON = 'application/json'
        APPLICATION_JSON_TYPES = %W{#{APPLICATION_JSON} application/vnd.git-lfs+json}.freeze
        ERROR_MESSAGE = 'You cannot perform write operations on a read-only instance'

        ALLOWLISTED_GIT_READ_ONLY_ROUTES = {
          'repositories/git_http' => %w{git_upload_pack}
        }.freeze

        ALLOWLISTED_GIT_LFS_BATCH_ROUTES = {
          'repositories/lfs_api' => %w{batch}
        }.freeze

        ALLOWLISTED_GIT_REVISION_ROUTES = {
          'projects/compare' => %w{create}
        }.freeze

        ALLOWLISTED_SESSION_ROUTES = {
          'sessions' => %w{destroy},
          'admin/sessions' => %w{create destroy}
        }.freeze

        GRAPHQL_URL = '/api/graphql'

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call
          if disallowed_request? && read_only?
            Gitlab::AppLogger.debug('GitLab ReadOnly: preventing possible non read-only operation')

            if json_request?
              return [403, { 'Content-Type' => APPLICATION_JSON }, [{ 'message' => ERROR_MESSAGE }.to_json]]
            else
              rack_flash.alert = ERROR_MESSAGE
              rack_session['flash'] = rack_flash.to_session_value

              return [301, { 'Location' => last_visited_url }, []]
            end
          end

          @app.call(@env)
        end

        private

        def disallowed_request?
          DISALLOWED_METHODS.include?(@env['REQUEST_METHOD']) &&
            !allowlisted_routes
        end

        # Overridden in EE module
        def read_only?
          Gitlab::Database.read_only?
        end

        def json_request?
          APPLICATION_JSON_TYPES.include?(request.media_type)
        end

        def rack_flash
          @rack_flash ||= ActionDispatch::Flash::FlashHash.from_session_value(rack_session)
        end

        def rack_session
          @env['rack.session']
        end

        def request
          @env['actionpack.request'] ||= ActionDispatch::Request.new(@env)
        end

        def last_visited_url
          @env['HTTP_REFERER'] || rack_session['user_return_to'] || Gitlab::Routing.url_helpers.root_url
        end

        def route_hash
          @route_hash ||= Rails.application.routes.recognize_path(request_url, { method: request.request_method }) rescue {}
        end

        def request_url
          request.url.chomp('/')
        end

        def request_path
          @request_path ||= request.path.chomp('/')
        end

        def relative_url
          File.join('', Gitlab.config.gitlab.relative_url_root).chomp('/')
        end

        # Overridden in EE module
        def allowlisted_routes
          workhorse_passthrough_route? || internal_route? || lfs_batch_route? || compare_git_revisions_route? || sidekiq_route? || session_route? || graphql_query?
        end

        # URL for requests passed through gitlab-workhorse to rails-web
        # https://gitlab.com/gitlab-org/gitlab-workhorse/-/merge_requests/12
        def workhorse_passthrough_route?
          # Calling route_hash may be expensive. Only do it if we think there's a possible match
          return false unless request.post? &&
            request_path.end_with?('.git/git-upload-pack')

          ALLOWLISTED_GIT_READ_ONLY_ROUTES[route_hash[:controller]]&.include?(route_hash[:action])
        end

        def internal_route?
          ReadOnly.internal_routes.any? { |path| request.path.include?(path) }
        end

        def compare_git_revisions_route?
          # Calling route_hash may be expensive. Only do it if we think there's a possible match
          return false unless request.post? && request.path.end_with?('compare')

          ALLOWLISTED_GIT_REVISION_ROUTES[route_hash[:controller]]&.include?(route_hash[:action])
        end

        # Batch upload requests are blocked in:
        # https://gitlab.com/gitlab-org/gitlab/blob/master/app/controllers/repositories/lfs_api_controller.rb#L106
        def lfs_batch_route?
          # Calling route_hash may be expensive. Only do it if we think there's a possible match
          return unless request_path.end_with?('/info/lfs/objects/batch')

          ALLOWLISTED_GIT_LFS_BATCH_ROUTES[route_hash[:controller]]&.include?(route_hash[:action])
        end

        def session_route?
          # Calling route_hash may be expensive. Only do it if we think there's a possible match
          return false unless request.post? && request_path.end_with?('/users/sign_out',
            '/admin/session', '/admin/session/destroy')

          ALLOWLISTED_SESSION_ROUTES[route_hash[:controller]]&.include?(route_hash[:action])
        end

        def sidekiq_route?
          request.path.start_with?("#{relative_url}/admin/sidekiq")
        end

        def graphql_query?
          request.post? && request.path.start_with?(File.join(relative_url, GRAPHQL_URL))
        end
      end
    end
  end
end

Gitlab::Middleware::ReadOnly::Controller.prepend_mod_with('Gitlab::Middleware::ReadOnly::Controller')

module Gitlab
  module Middleware
    class ReadOnly
      class Controller
        DISALLOWED_METHODS = %w(POST PATCH PUT DELETE).freeze
        APPLICATION_JSON = 'application/json'.freeze
        ERROR_MESSAGE = 'You cannot perform write operations on a read-only instance'.freeze

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call
          if disallowed_request? && Gitlab::Database.read_only?
            Rails.logger.debug('GitLab ReadOnly: preventing possible non read-only operation')

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
            !whitelisted_routes
        end

        def json_request?
          request.media_type == APPLICATION_JSON
        end

        def rack_flash
          @rack_flash ||= ActionDispatch::Flash::FlashHash.from_session_value(rack_session)
        end

        def rack_session
          @env['rack.session']
        end

        def request
          @env['rack.request'] ||= Rack::Request.new(@env)
        end

        def last_visited_url
          @env['HTTP_REFERER'] || rack_session['user_return_to'] || Gitlab::Routing.url_helpers.root_url
        end

        def route_hash
          @route_hash ||= Rails.application.routes.recognize_path(request.url, { method: request.request_method }) rescue {}
        end

        def whitelisted_routes
          grack_route || ReadOnly.internal_routes.any? { |path| request.path.include?(path) } || lfs_route || sidekiq_route
        end

        def sidekiq_route
          request.path.start_with?('/admin/sidekiq')
        end

        def grack_route
          # Calling route_hash may be expensive. Only do it if we think there's a possible match
          return false unless request.path.end_with?('.git/git-upload-pack')

          route_hash[:controller] == 'projects/git_http' && route_hash[:action] == 'git_upload_pack'
        end

        def lfs_route
          # Calling route_hash may be expensive. Only do it if we think there's a possible match
          return false unless request.path.end_with?('/info/lfs/objects/batch')

          route_hash[:controller] == 'projects/lfs_api' && route_hash[:action] == 'batch'
        end
      end
    end
  end
end

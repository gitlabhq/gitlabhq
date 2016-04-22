module Gitlab
  module Middleware
    class ReadonlyGeo
      DISALLOWED_METHODS = %w(POST PATCH PUT DELETE)
      WHITELISTED = %w(api/v3/internal api/v3/geo/refresh_wikis api/v3/geo/receive_events)
      APPLICATION_JSON = 'application/json'

      def initialize(app)
        @app = app
      end

      def call(env)
        @env = env

        if disallowed_request? && Gitlab::Geo.secondary?
          Rails.logger.debug('GitLab Geo: preventing possible non readonly operation')
          error_message = 'You cannot do writing operations on a secondary GitLab Geo instance'

          if json_request?
            return [403, { 'Content-Type' => 'application/json' }, [{ 'message' => error_message }.to_json]]
          else
            rack_flash.alert = error_message
            rack_session['flash'] = rack_flash.to_session_value

            return [301, { 'Location' => last_visited_url }, []]
          end
        end

        @app.call(env)
      end

      private

      def disallowed_request?
        DISALLOWED_METHODS.include?(@env['REQUEST_METHOD']) && !whitelisted_routes
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
        @request ||= Rack::Request.new(@env)
      end

      def last_visited_url
        @env['HTTP_REFERER'] || rack_session['user_return_to'] || Rails.application.routes.url_helpers.root_url
      end

      def route_hash
        @route_hash ||= Rails.application.routes.recognize_path(request.url, { method: request.request_method }) rescue {}
      end

      def whitelisted_routes
        logout_route || grack_route || WHITELISTED.any? { |path| @request.path.include?(path) } || sidekiq_route
      end

      def logout_route
        route_hash[:controller] == 'sessions' && route_hash[:action] == 'destroy'
      end

      def sidekiq_route
        @request.path.start_with?('/admin/sidekiq')
      end

      def grack_route
        @request.path.end_with?('.git/git-upload-pack')
      end
    end
  end
end

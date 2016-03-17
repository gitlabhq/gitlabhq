module Gitlab
  module Middleware
    class ReadonlyGeo
      DISALLOWED_METHODS = %w(POST PATCH PUT DELETE)
      WHITELISTED = %w(api/v3/internal api/v3/geo/refresh_projects api/v3/geo/refresh_wikis)

      def initialize(app)
        @app = app
      end

      def call(env)
        @env = env

        if disallowed_request? && Gitlab::Geo.secondary?
          Rails.logger.debug('Gitlab Geo: preventing possible non readonly operation')

          rack_flash.alert = 'You cannot do writing operations on a secondary Gitlab Geo instance'
          rack_session['flash'] = rack_flash.to_session_value

          return [301, { 'Location' => last_visited_url }, []]
        end

        @app.call(env)
      end

      private

      def disallowed_request?
        DISALLOWED_METHODS.include?(@env['REQUEST_METHOD']) && !whitelisted_routes
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
        logout_route || WHITELISTED.any? { |path| @request.path.include?(path) }
      end

      def logout_route
        route_hash[:controller] == 'sessions' && route_hash[:action] == 'destroy'
      end
    end
  end
end

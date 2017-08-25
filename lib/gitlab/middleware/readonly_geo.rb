module Gitlab
  module Middleware
    class ReadonlyGeo
      APPLICATION_JSON = 'application/json'.freeze
      API_VERSIONS = (3..4)
      DISALLOWED_METHODS = %w(POST PATCH PUT DELETE).freeze
      DOWNLOAD_OPERATION = 'download'.freeze

      def initialize(app)
        @app = app
        @whitelisted = internal_routes
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

      def internal_routes
        API_VERSIONS.flat_map { |version| "api/v#{version}/internal" }
      end

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
        @env['rack.request'] ||= Rack::Request.new(@env)
      end

      def last_visited_url
        @env['HTTP_REFERER'] || rack_session['user_return_to'] || Rails.application.routes.url_helpers.root_url
      end

      def route_hash
        @route_hash ||= Rails.application.routes.recognize_path(request.url, { method: request.request_method }) rescue {}
      end

      def whitelisted_routes
        logout_route || grack_route || @whitelisted.any? { |path| request.path.include?(path) } || lfs_download_route
      end

      def logout_route
        route_hash[:controller] == 'sessions' && route_hash[:action] == 'destroy'
      end

      def sidekiq_route
        request.path.start_with?('/admin/sidekiq')
      end

      def grack_route
        request.path.end_with?('.git/git-upload-pack')
      end

      def lfs_download_route
        request.path.end_with?('/info/lfs/objects/batch') && lfs_download_operation?
      end

      def lfs_download_operation?
        params = parse_formatted_parameters
        params[:operation] == DOWNLOAD_OPERATION
      end

      def parse_formatted_parameters
        return {} if request.content_length.to_i.zero?

        data = ActiveSupport::JSON.decode(request.body.read) rescue {}
        request.body.rewind
        data.with_indifferent_access
      end
    end
  end
end

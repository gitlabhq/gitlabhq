# frozen_string_literal: true

module Gitlab
  module Middleware
    # Every GitLab Cell shares the same session cookie *name* (e.g. `_gitlab_session`);
    # only the cookie *value* is prefixed with the owning cell (e.g. `cell-3-<sid>`).
    #
    # When path-based routing sends a request to a cell other than the one that owns
    # the session cookie, and the visitor is not authenticated there (cross-cell
    # sessions are not resolvable), Rails would otherwise mint a brand new, empty
    # session and write it back under the very same cookie name, overwriting the
    # browser's cookie for the owning cell and orphaning that session.
    #
    # This middleware detects that case and marks the session to be skipped, so no
    # `Set-Cookie` is sent and nothing is persisted, leaving the owning cell's cookie
    # intact in the browser.
    #
    # A controller calls {.allow_overwrite!} when the visitor must start a session on
    # this cell, such as the sign-in page that the router sends here for a login it owns.
    #
    # See https://gitlab.com/gitlab-com/gl-infra/tenant-scale/cells-infrastructure/team/-/work_items/890
    class PreventCrossCellSessionOverwrite
      ALLOW_OVERWRITE_ENV_KEY = 'gitlab.cells.allow_session_overwrite'

      # Lets this request write its session even when the cookie belongs to another cell.
      #
      # @param request [ActionDispatch::Request]
      # @return [void]
      def self.allow_overwrite!(request)
        request.env[ALLOW_OVERWRITE_ENV_KEY] = true

        nil
      end

      # @param env [Hash] the Rack env
      # @return [Boolean] whether a controller allowed this request to write its session
      def self.overwrite_allowed?(env)
        env[ALLOW_OVERWRITE_ENV_KEY] == true
      end

      # @param app [Object] the Rack app
      # @param session_cookie_token_prefix [String] this cell's prefix (e.g. "cell-1"),
      #   as already computed in config/initializers/session_store.rb. Empty string means
      #   cells are not enabled and the middleware is a no-op.
      def initialize(app, session_cookie_token_prefix: "")
        @app = app
        @session_cookie_token_prefix = session_cookie_token_prefix
      end

      def call(env)
        result = @app.call(env)

        env['rack.session.options'][:skip] = true if skip_session_write?(env)

        result
      end

      private

      def skip_session_write?(env)
        return false if self.class.overwrite_allowed?(env)
        return false unless Gitlab.config.cell.enabled
        return false if @session_cookie_token_prefix.blank?
        return false unless env['rack.session.options']

        return false unless Feature.enabled?(:prevent_cross_cell_session_overwrite, :current_request,
          type: :gitlab_com_derisk)

        return false if authenticated?(env)

        foreign_cell_cookie?(env)
      end

      def authenticated?(env)
        warden = env['warden']
        user = catch(:warden) { warden && warden.user } # rubocop:disable Cop/BanCatchThrow -- outside Warden::Manager
        user.present?
      end

      def foreign_cell_cookie?(env)
        cookie_value = Rack::Request.new(env).cookies[cookie_key].to_s
        return false unless cookie_value.start_with?("cell-")

        !cookie_value.start_with?("#{@session_cookie_token_prefix}-")
      end

      def cookie_key
        Rails.application.config.session_options[:key]
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Middleware
    class StaticAssetsAuthorization
      include Gitlab::Utils::StrongMemoize

      VSCODE_ASSETS_PATH_PREFIX = '/assets/webpack/gitlab-web-ide-vscode-workbench'
      FONTS_ASSETS_PATH_PREFIX = '/assets/gitlab-mono'

      def initialize(app)
        @app = app
      end

      def call(env)
        # This middleware issues authorization headers for static assets requests. This functionality
        # is relevant to the Web IDE feature. In production environments, GitLab Workhorse
        # serves static assets. GitLab Workhorse sends an OPTIONS request to the Rails service
        # to dynamically generate authorization headers for Web IDE VSCode static assets.
        #
        # These authorization headers prevent cross-origin attacks by ensuring that 3rd-party
        # websites can't load these assets and in turn, inject arbitrary code into the Web IDE.
        #
        # See the workhorse implementation in workhorse/internal/staticpages/servefile.go in the
        # current repository.
        request = ActionDispatch::Request.new(env)

        return @app.call(env) unless handles_request?(request)

        return [401, {}, []] if deny_vscode_assets_access?(request)

        headers = get_authorization_headers(request)

        return [204, headers, []] if request.method == 'OPTIONS'

        # Rails does not serve static assets on production environments.
        # Workhorse only sends assets HTTP requests on the development environment (18.6):
        #
        # https://gitlab.com/gitlab-org/gitlab/-/blob/18-6-stable-ee/workhorse/internal/upstream/routes.go?ref_type=heads#L311
        #
        # The code below was included to handle the scenario where GitLab font
        # assets are served by the Rails assets pipeline in dev and test environments.
        # Otherwise, tests fail.
        status, base_headers, body = @app.call(env)

        headers.merge!(base_headers)

        [status, headers, body]
      end

      private

      def handles_request?(request)
        %w[OPTIONS GET HEAD].include?(request.method) &&
          (vscode_assets_path?(request) || fonts_assets_path?(request))
      end

      def deny_vscode_assets_access?(request)
        gitlab_host?(request) && vscode_assets_path?(request) &&
          !::WebIde::ExtensionMarketplace.single_origin_fallback_enabled?
      end

      def gitlab_host?(request)
        request.headers['Host'] == gitlab_host
      end

      def gitlab_host
        gitlab_url = URI.parse(Gitlab.config.gitlab.url)
        host = gitlab_url.host
        port = gitlab_url.port

        port == gitlab_url.default_port ? host : "#{host}:#{port}"
      end
      strong_memoize_attr :gitlab_host

      def vscode_assets_path?(request)
        request.path.start_with?(VSCODE_ASSETS_PATH_PREFIX)
      end

      def fonts_assets_path?(request)
        request.path.start_with?(FONTS_ASSETS_PATH_PREFIX)
      end

      def get_authorization_headers(request)
        origin_header = request.headers['Origin']
        match_origin = ::WebIde::ExtensionMarketplace.origin_matches_extension_host_regexp.match(origin_header)
        base_domain = ::WebIde::ExtensionMarketplace.extension_host_domain
        response_headers = {}

        if match_origin
          response_headers.merge!({
            'Access-Control-Allow-Origin' => build_allowed_origin_url(match_origin[1], base_domain),
            'Access-Control-Allow-Methods' => 'GET, HEAD, OPTIONS',
            'Vary' => 'Origin'
          })
        end

        response_headers.merge!({
          'Cross-Origin-Opener-Policy' => 'same-origin',
          'Cross-Origin-Resource-Policy' => 'same-site',
          'Content-Security-Policy' => "frame-ancestors 'self' https://*.#{base_domain} #{Gitlab.config.gitlab.url};"
        })

        response_headers
      end

      def build_allowed_origin_url(allowed_subdomain, base_domain)
        "https://#{allowed_subdomain}.#{base_domain}"
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module ContentSecurityPolicy
    class ConfigLoader
      DIRECTIVES = %w(base_uri child_src connect_src default_src font_src
                      form_action frame_ancestors frame_src img_src manifest_src
                      media_src object_src report_uri script_src style_src worker_src).freeze

      DEFAULT_FALLBACK_VALUE = '<default_value>'

      def self.default_enabled
        Rails.env.development? || Rails.env.test?
      end

      def self.default_directives
        directives = {
          'default_src' => "'self'",
          'base_uri' => "'self'",
          'connect_src' => ContentSecurityPolicy::Directives.connect_src,
          'font_src' => "'self'",
          'form_action' => "'self' https: http:",
          'frame_ancestors' => "'self'",
          'frame_src' => ContentSecurityPolicy::Directives.frame_src,
          'img_src' => "'self' data: blob: http: https:",
          'manifest_src' => "'self'",
          'media_src' => "'self' data: blob: http: https:",
          'script_src' => ContentSecurityPolicy::Directives.script_src,
          'style_src' => ContentSecurityPolicy::Directives.style_src,
          'worker_src' => "#{Gitlab::Utils.append_path(Gitlab.config.gitlab.url, 'assets/')} blob: data:",
          'object_src' => "'none'",
          'report_uri' => nil
        }

        # connect_src with 'self' includes https/wss variations of the origin,
        # however, safari hasn't covered this yet and we need to explicitly add
        # support for websocket origins until Safari catches up with the specs
        if Rails.env.development?
          allow_webpack_dev_server(directives)
          allow_letter_opener(directives)
          allow_snowplow_micro(directives) if Gitlab::Tracking.snowplow_micro_enabled?
        end

        allow_websocket_connections(directives)
        allow_cdn(directives, Settings.gitlab.cdn_host) if Settings.gitlab.cdn_host.present?
        allow_zuora(directives) if Gitlab.com?
        # Support for Sentry setup via configuration files will be removed in 16.0
        # in favor of Gitlab::CurrentSettings.
        allow_legacy_sentry(directives) if Gitlab.config.sentry&.enabled && Gitlab.config.sentry&.clientside_dsn
        allow_sentry(directives) if Gitlab::CurrentSettings.try(:sentry_enabled) && Gitlab::CurrentSettings.try(:sentry_clientside_dsn)
        allow_framed_gitlab_paths(directives)
        allow_customersdot(directives) if ENV['CUSTOMER_PORTAL_URL'].present?
        allow_review_apps(directives) if ENV['REVIEW_APPS_ENABLED']

        # The follow section contains workarounds to patch Safari's lack of support for CSP Level 3
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/343579
        # frame-src was deprecated in CSP level 2 in favor of child-src
        # CSP level 3 "undeprecated" frame-src and browsers fall back on child-src if it's missing
        # However Safari seems to read child-src first so we'll just keep both equal
        append_to_directive(directives, 'child_src', directives['frame_src'])

        # Safari also doesn't support worker-src and only checks child-src
        # So for compatibility until it catches up to other browsers we need to
        # append worker-src's content to child-src
        append_to_directive(directives, 'child_src', directives['worker_src'])

        directives
      end

      def initialize(csp_directives)
        # Using <default_value> falls back to the default values.
        directives = csp_directives.reject { |_, value| value == DEFAULT_FALLBACK_VALUE }
        @merged_csp_directives =
          HashWithIndifferentAccess.new(directives)
                                   .reverse_merge(::Gitlab::ContentSecurityPolicy::ConfigLoader.default_directives)
      end

      def load(policy)
        DIRECTIVES.each do |directive|
          arguments = arguments_for(directive)

          next unless arguments.present?

          policy.public_send(directive, *arguments) # rubocop:disable GitlabSecurity/PublicSend
        end
      end

      private

      def arguments_for(directive)
        # In order to disable a directive, the user can explicitly
        # set a falsy value like nil, false or empty string
        arguments = @merged_csp_directives[directive]
        return unless arguments.present? && arguments.is_a?(String)

        arguments.strip.split(' ').map(&:strip)
      end

      def self.allow_websocket_connections(directives)
        http_ports = [80, 443]
        host = Gitlab.config.gitlab.host
        port = Gitlab.config.gitlab.port
        secure = Gitlab.config.gitlab.https
        protocol = secure ? 'wss' : 'ws'

        ws_url = "#{protocol}://#{host}"

        unless http_ports.include?(port)
          ws_url = "#{ws_url}:#{port}"
        end

        append_to_directive(directives, 'connect_src', ws_url)
      end

      def self.allow_webpack_dev_server(directives)
        secure = Settings.webpack.dev_server['https']
        host_and_port = "#{Settings.webpack.dev_server['host']}:#{Settings.webpack.dev_server['port']}"
        http_url = "#{secure ? 'https' : 'http'}://#{host_and_port}"
        ws_url = "#{secure ? 'wss' : 'ws'}://#{host_and_port}"

        append_to_directive(directives, 'connect_src', "#{http_url} #{ws_url}")
      end

      def self.allow_cdn(directives, cdn_host)
        append_to_directive(directives, 'script_src', cdn_host)
        append_to_directive(directives, 'style_src', cdn_host)
        append_to_directive(directives, 'font_src', cdn_host)
        append_to_directive(directives, 'worker_src', cdn_host)
        append_to_directive(directives, 'frame_src', cdn_host)
      end

      def self.zuora_host
        "https://*.zuora.com/apps/PublicHostedPageLite.do"
      end

      def self.allow_zuora(directives)
        append_to_directive(directives, 'frame_src', zuora_host)
      end

      def self.append_to_directive(directives, directive, text)
        directives[directive] = "#{directives[directive]} #{text}".strip
      end

      def self.allow_customersdot(directives)
        customersdot_host = ENV['CUSTOMER_PORTAL_URL']

        append_to_directive(directives, 'frame_src', customersdot_host)
      end

      def self.allow_legacy_sentry(directives)
        # Support for Sentry setup via configuration files will be removed in 16.0
        # in favor of Gitlab::CurrentSettings.
        sentry_dsn = Gitlab.config.sentry.clientside_dsn
        sentry_uri = URI(sentry_dsn)

        append_to_directive(directives, 'connect_src', "#{sentry_uri.scheme}://#{sentry_uri.host}")
      end

      def self.allow_sentry(directives)
        sentry_dsn = Gitlab::CurrentSettings.sentry_clientside_dsn
        sentry_uri = URI(sentry_dsn)

        append_to_directive(directives, 'connect_src', "#{sentry_uri.scheme}://#{sentry_uri.host}")
      end

      def self.allow_letter_opener(directives)
        append_to_directive(directives, 'frame_src', Gitlab::Utils.append_path(Gitlab.config.gitlab.url, '/rails/letter_opener/'))
      end

      def self.allow_snowplow_micro(directives)
        url = URI.join(Gitlab::Tracking::Destinations::SnowplowMicro.new.uri, '/').to_s
        append_to_directive(directives, 'connect_src', url)
      end

      # Using 'self' in the CSP introduces several CSP bypass opportunities
      # for this reason we list the URLs where GitLab frames itself instead
      def self.allow_framed_gitlab_paths(directives)
        ['/admin/', '/assets/', '/-/speedscope/index.html', '/-/sandbox/'].map do |path|
          append_to_directive(directives, 'frame_src', Gitlab::Utils.append_path(Gitlab.config.gitlab.url, path))
        end
      end

      def self.allow_review_apps(directives)
        # Allow-listed to allow POSTs to https://gitlab.com/api/v4/projects/278964/merge_requests/:merge_request_iid/visual_review_discussions
        append_to_directive(directives, 'connect_src', 'https://gitlab.com/api/v4/projects/278964/merge_requests/')
      end
    end
  end
end

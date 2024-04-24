# frozen_string_literal: true

module Gitlab
  module ContentSecurityPolicy
    class ConfigLoader
      DIRECTIVES = %w[
        base_uri child_src connect_src default_src font_src form_action
        frame_ancestors frame_src img_src manifest_src media_src object_src
        report_uri script_src style_src worker_src
      ].freeze
      DEFAULT_FALLBACK_VALUE = '<default_value>'
      HTTP_PORTS = [80, 443].freeze

      class << self
        def default_enabled
          Rails.env.development? || Rails.env.test?
        end

        def default_directives
          directives = default_directives_defaults

          allow_development_tooling(directives)
          allow_websocket_connections(directives)
          allow_lfs(directives)
          allow_cdn(directives)
          allow_zuora(directives)
          allow_sentry(directives)
          allow_framed_gitlab_paths(directives)
          allow_customersdot(directives)
          csp_level_3_backport(directives)
          add_browsersdk_tracking(directives)

          directives
        end

        def default_directives_defaults
          {
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
            'worker_src' => ContentSecurityPolicy::Directives.worker_src,
            'object_src' => "'none'",
            'report_uri' => nil
          }
        end

        # connect_src with 'self' includes https/wss variations of the origin,
        # however, safari hasn't covered this yet and we need to explicitly add
        # support for websocket origins until Safari catches up with the specs
        def allow_development_tooling(directives)
          return unless Rails.env.development?

          allow_webpack_dev_server(directives)
          allow_letter_opener(directives)
          allow_snowplow_micro(directives) if Gitlab::Tracking.snowplow_micro_enabled?
        end

        def allow_webpack_dev_server(directives)
          secure = Settings.webpack.dev_server['https']
          host_and_port = "#{Settings.webpack.dev_server['host']}:#{Settings.webpack.dev_server['port']}"
          http_url = "#{secure ? 'https' : 'http'}://#{host_and_port}"
          ws_url = "#{secure ? 'wss' : 'ws'}://#{host_and_port}"

          append_to_directive(directives, 'connect_src', "#{http_url} #{ws_url}")
        end

        def allow_letter_opener(directives)
          url = Gitlab::Utils.append_path(Gitlab.config.gitlab.url, '/rails/letter_opener/')
          append_to_directive(directives, 'frame_src', url)
        end

        def allow_snowplow_micro(directives)
          url = URI.join(Gitlab::Tracking::Destinations::SnowplowMicro.new.uri, '/').to_s
          append_to_directive(directives, 'connect_src', url)
        end

        def add_browsersdk_tracking(directives)
          return if directives.blank?
          return unless Gitlab.com? && ENV['GITLAB_ANALYTICS_URL'].present?

          default_connect_src = directives['connect-src'] || directives['default-src']
          connect_src_values = Array.wrap(default_connect_src) | [ENV['GITLAB_ANALYTICS_URL']]

          append_to_directive(directives, 'connect_src', connect_src_values.join(' '))
        end

        def allow_lfs(directives)
          return unless Gitlab.config.lfs.enabled && LfsObjectUploader.object_store_enabled? && LfsObjectUploader.direct_download_enabled?

          lfs_url = build_lfs_url
          return unless lfs_url.present?

          append_to_directive(directives, 'connect_src', lfs_url)
        end

        def allow_websocket_connections(directives)
          host = Gitlab.config.gitlab.host
          port = Gitlab.config.gitlab.port
          secure = Gitlab.config.gitlab.https
          protocol = secure ? 'wss' : 'ws'

          ws_url = "#{protocol}://#{host}"
          ws_url = "#{ws_url}:#{port}" unless HTTP_PORTS.include?(port)

          append_to_directive(directives, 'connect_src', ws_url)
        end

        def allow_cdn(directives)
          cdn_host = Settings.gitlab.cdn_host.presence
          return unless cdn_host

          append_to_directive(directives, 'script_src', cdn_host)
          append_to_directive(directives, 'style_src', cdn_host)
          append_to_directive(directives, 'font_src', cdn_host)
          append_to_directive(directives, 'worker_src', cdn_host)
          append_to_directive(directives, 'frame_src', cdn_host)
        end

        def allow_zuora(directives)
          return unless Gitlab.com?

          append_to_directive(directives, 'frame_src', zuora_host)
        end

        def allow_sentry(directives)
          return unless sentry_client_side_dsn_enabled?

          sentry_uri = URI(Gitlab::CurrentSettings.sentry_clientside_dsn)

          append_to_directive(directives, 'connect_src', "#{sentry_uri.scheme}://#{sentry_uri.host}")
        end

        def sentry_client_side_dsn_enabled?
          Gitlab::CurrentSettings.try(:sentry_enabled) && Gitlab::CurrentSettings.try(:sentry_clientside_dsn)
        end

        # Using 'self' in the CSP introduces several CSP bypass opportunities
        # for this reason we list the URLs where GitLab frames itself instead
        def allow_framed_gitlab_paths(directives)
          ['/admin/', '/assets/', '/-/speedscope/index.html', '/-/sandbox/'].map do |path|
            append_to_directive(directives, 'frame_src', Gitlab::Utils.append_path(Gitlab.config.gitlab.url, path))
          end
        end

        def allow_customersdot(directives)
          customersdot_host = ENV['CUSTOMER_PORTAL_URL'].presence
          return unless customersdot_host

          append_to_directive(directives, 'frame_src', customersdot_host)
        end

        # The follow contains workarounds to patch Safari's lack of support for CSP Level 3
        def csp_level_3_backport(directives)
          # See https://gitlab.com/gitlab-org/gitlab/-/issues/343579
          # frame-src was deprecated in CSP level 2 in favor of child-src
          # CSP level 3 "undeprecated" frame-src and browsers fall back on child-src if it's missing
          # However Safari seems to read child-src first so we'll just keep both equal
          append_to_directive(directives, 'child_src', directives['frame_src'])

          # Safari also doesn't support worker-src and only checks child-src
          # So for compatibility until it catches up to other browsers we need to
          # append worker-src's content to child-src
          append_to_directive(directives, 'child_src', directives['worker_src'])
        end

        def append_to_directive(directives, directive, text)
          directives[directive] = "#{directives[directive]} #{text}".strip
        end

        def zuora_host
          "https://*.zuora.com/apps/PublicHostedPageLite.do"
        end

        def build_lfs_url
          uploader = LfsObjectUploader.new(nil)
          fog = CarrierWave::Storage::Fog.new(uploader)
          fog_file = CarrierWave::Storage::Fog::File.new(uploader, fog, nil)
          fog_file.public_url || fog_file.url
        end
      end

      def initialize(csp_directives)
        # Using <default_value> falls back to the default values.
        @merged_csp_directives = csp_directives
          .reject { |_, value| value == DEFAULT_FALLBACK_VALUE }
          .with_indifferent_access
          .reverse_merge(ConfigLoader.default_directives)
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
        return unless arguments.is_a?(String)

        arguments.split(' ')
      end
    end
  end
end

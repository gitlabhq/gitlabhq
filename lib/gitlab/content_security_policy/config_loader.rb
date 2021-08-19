# frozen_string_literal: true

module Gitlab
  module ContentSecurityPolicy
    class ConfigLoader
      DIRECTIVES = %w(base_uri child_src connect_src default_src font_src
                      form_action frame_ancestors frame_src img_src manifest_src
                      media_src object_src report_uri script_src style_src worker_src).freeze

      def self.default_enabled
        Rails.env.development? || Rails.env.test?
      end

      def self.default_directives
        directives = {
          'default_src' => "'self'",
          'base_uri' => "'self'",
          'connect_src' => "'self'",
          'font_src' => "'self'",
          'form_action' => "'self' https: http:",
          'frame_ancestors' => "'self'",
          'frame_src' => "'self' https://www.google.com/recaptcha/ https://www.recaptcha.net/ https://content.googleapis.com https://content-compute.googleapis.com https://content-cloudbilling.googleapis.com https://content-cloudresourcemanager.googleapis.com",
          'img_src' => "'self' data: blob: http: https:",
          'manifest_src' => "'self'",
          'media_src' => "'self'",
          'script_src' => "'strict-dynamic' 'self' 'unsafe-inline' 'unsafe-eval' https://www.google.com/recaptcha/ https://www.recaptcha.net https://apis.google.com",
          'style_src' => "'self' 'unsafe-inline'",
          'worker_src' => "'self' blob: data:",
          'object_src' => "'none'",
          'report_uri' => nil
        }

        # frame-src was deprecated in CSP level 2 in favor of child-src
        # CSP level 3 "undeprecated" frame-src and browsers fall back on child-src if it's missing
        # However Safari seems to read child-src first so we'll just keep both equal
        directives['child_src'] = directives['frame_src']

        allow_webpack_dev_server(directives) if Rails.env.development?
        allow_cdn(directives, Settings.gitlab.cdn_host) if Settings.gitlab.cdn_host.present?
        allow_customersdot(directives) if Rails.env.development? && ENV['CUSTOMER_PORTAL_URL'].present?
        allow_sentry(directives) if Gitlab.config.sentry&.enabled && Gitlab.config.sentry&.clientside_dsn

        directives
      end

      def initialize(csp_directives)
        @csp_directives = HashWithIndifferentAccess.new(csp_directives)
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
        arguments = @csp_directives[directive.to_s]

        return unless arguments.present? && arguments.is_a?(String)

        arguments.strip.split(' ').map(&:strip)
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
      end

      def self.append_to_directive(directives, directive, text)
        directives[directive] = "#{directives[directive]} #{text}".strip
      end

      def self.allow_customersdot(directives)
        customersdot_host = ENV['CUSTOMER_PORTAL_URL']

        append_to_directive(directives, 'frame_src', customersdot_host)
      end

      def self.allow_sentry(directives)
        sentry_dsn = Gitlab.config.sentry.clientside_dsn
        sentry_uri = URI(sentry_dsn)
        sentry_uri.user = nil

        append_to_directive(directives, 'connect_src', sentry_uri.to_s)
      end
    end
  end
end

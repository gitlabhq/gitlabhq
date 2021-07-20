# frozen_string_literal: true

module Gitlab
  module ContentSecurityPolicy
    class ConfigLoader
      DIRECTIVES = %w(base_uri child_src connect_src default_src font_src
                      form_action frame_ancestors frame_src img_src manifest_src
                      media_src object_src report_uri script_src style_src worker_src).freeze

      def self.default_settings_hash
        settings_hash = {
          'enabled' => Rails.env.development? || Rails.env.test?,
          'report_only' => false,
          'directives' => {
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
        }

        # frame-src was deprecated in CSP level 2 in favor of child-src
        # CSP level 3 "undeprecated" frame-src and browsers fall back on child-src if it's missing
        # However Safari seems to read child-src first so we'll just keep both equal
        settings_hash['directives']['child_src'] = settings_hash['directives']['frame_src']

        allow_webpack_dev_server(settings_hash) if Rails.env.development?
        allow_cdn(settings_hash) if ENV['GITLAB_CDN_HOST'].present?
        allow_customersdot(settings_hash) if Rails.env.development? && ENV['CUSTOMER_PORTAL_URL'].present?

        settings_hash
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

      def self.allow_webpack_dev_server(settings_hash)
        secure = Settings.webpack.dev_server['https']
        host_and_port = "#{Settings.webpack.dev_server['host']}:#{Settings.webpack.dev_server['port']}"
        http_url = "#{secure ? 'https' : 'http'}://#{host_and_port}"
        ws_url = "#{secure ? 'wss' : 'ws'}://#{host_and_port}"

        append_to_directive(settings_hash, 'connect_src', "#{http_url} #{ws_url}")
      end

      def self.allow_cdn(settings_hash)
        cdn_host = ENV['GITLAB_CDN_HOST']

        append_to_directive(settings_hash, 'script_src', cdn_host)
        append_to_directive(settings_hash, 'style_src', cdn_host)
        append_to_directive(settings_hash, 'font_src', cdn_host)
      end

      def self.append_to_directive(settings_hash, directive, text)
        settings_hash['directives'][directive] = "#{settings_hash['directives'][directive]} #{text}".strip
      end

      def self.allow_customersdot(settings_hash)
        customersdot_host = ENV['CUSTOMER_PORTAL_URL']

        append_to_directive(settings_hash, 'frame_src', customersdot_host)
      end
    end
  end
end

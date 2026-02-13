# frozen_string_literal: true

module Banzai
  module Filter
    # Proxies images/assets through another server.  Reduces mixed content warnings
    # as well as hiding the customer's IP address when requesting images.
    # Copies the original img `src` to `data-canonical-src` and replaces the
    # `src` with a new url to the proxy server.
    #
    # See https://docs.gitlab.com/security/asset_proxy/ for more information.
    #
    # Based on https://github.com/gjtorikian/html-pipeline/blob/v2.14.3/lib/html/pipeline/camo_filter.rb
    class AssetProxyFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck
      include Concerns::AssetProxying

      def initialize(text, context = nil, result = nil)
        super
      end

      def call
        return doc unless asset_proxy_enabled?

        doc.search('img').each do |element|
          original_src = element['src']
          next unless original_src

          next if can_skip_asset_proxy_for_url?(original_src)

          element['src'] = asset_proxy_url(original_src)
          element['data-canonical-src'] = original_src
        end
        doc
      end

      def validate
        validate_asset_proxying
      end

      def self.transform_context(context)
        context[:disable_asset_proxy] = !Gitlab.config.asset_proxy.enabled

        unless context[:disable_asset_proxy]
          context[:asset_proxy_enabled]       = !context[:disable_asset_proxy]
          context[:asset_proxy]               = Gitlab.config.asset_proxy.url
          context[:asset_proxy_secret_key]    = Gitlab.config.asset_proxy.secret_key
          context[:asset_proxy_domain_regexp] = Gitlab.config.asset_proxy.domain_regexp
        end

        context
      end

      # called during an initializer. Caching the values in Gitlab.config significantly increased
      # performance, rather than querying Gitlab::CurrentSettings.current_application_settings
      # over and over.  However, this does mean that the Rails servers need to get restarted
      # whenever the application settings are changed
      def self.initialize_settings
        application_settings           = Gitlab::CurrentSettings.current_application_settings
        Gitlab.config['asset_proxy'] ||= GitlabSettings::Options.build({})

        if application_settings.respond_to?(:asset_proxy_enabled)
          Gitlab.config.asset_proxy['enabled']        = application_settings.asset_proxy_enabled
          Gitlab.config.asset_proxy['url']            = application_settings.asset_proxy_url
          Gitlab.config.asset_proxy['secret_key']     = application_settings.asset_proxy_secret_key
          Gitlab.config.asset_proxy['allowlist']      = determine_allowlist(application_settings)
          Gitlab.config.asset_proxy['domain_regexp']  = host_regexp_for_allowlist(Gitlab.config.asset_proxy.allowlist)
          if Gitlab.config.asset_proxy.enabled
            Gitlab.config.asset_proxy['csp_directives'] =
              csp_for_allowlist(Gitlab.config.asset_proxy.allowlist, asset_proxy_url: Gitlab.config.asset_proxy.url)
          end
        else
          Gitlab.config.asset_proxy['enabled'] = ::ApplicationSetting.defaults[:asset_proxy_enabled]
        end
      end

      def self.host_regexp_for_allowlist(allowlist)
        return if allowlist.empty?

        escaped = allowlist.map { |domain| Regexp.escape(domain).gsub('\*', '.*?') }
        Regexp.new("^(#{escaped.join('|')})$", Regexp::IGNORECASE)
      end

      def self.csp_for_allowlist(allowlist, asset_proxy_url:)
        # See https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Content-Security-Policy#host-source.

        # Permit assets on the GitLab host itself.
        src = [:self]

        # We need to permit the asset proxy URL itself for it to work in the Mermaid sandbox.
        # The setting is already validated to be a valid URL; we need to ensure it ends in a
        # forward-slash for the CSP to ensure we permit the entire prefix.
        asset_proxy_url += '/' unless asset_proxy_url.ends_with?('/')
        src << asset_proxy_url

        # We use HTTP (and not HTTPS) as the scheme as administrators may allowlist a host with the expectation that
        # they can use resources from it over HTTP, such as in an intranet.  Allowing http://... in a CSP also
        # explicitly permits HTTPS for the same directive. ("When matching schemes, secure upgrades are allowed.")
        allowlist.each do |host|
          src << "http://#{host}:*"
        end

        src
      end

      def self.determine_allowlist(application_settings)
        application_settings.try(:asset_proxy_allowlist).presence ||
          application_settings.try(:asset_proxy_whitelist).presence ||
          [Gitlab.config.gitlab.host]
      end
    end
  end
end

# frozen_string_literal: true

module Banzai
  module Filter
    # Proxy's images/assets to another server.  Reduces mixed content warnings
    # as well as hiding the customer's IP address when requesting images.
    # Copies the original img `src` to `data-canonical-src` then replaces the
    # `src` with a new url to the proxy server.
    #
    # Based on https://github.com/gjtorikian/html-pipeline/blob/v2.14.3/lib/html/pipeline/camo_filter.rb
    class AssetProxyFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck

      def initialize(text, context = nil, result = nil)
        super
      end

      def call
        return doc unless asset_proxy_enabled?

        doc.search('img').each do |element|
          original_src = element['src']
          next unless original_src

          begin
            uri = URI.parse(original_src)

            # Skip URLs like `/path.ext` or `path.ext` which are relative to the current host
            next if uri.relative? && uri.host.nil? && original_src.match(%r{\A/*})[0].length < 2
            next if asset_host_allowed?(uri.host)
          rescue StandardError
            # Ignored
          end

          element['src'] = asset_proxy_url(original_src)
          element['data-canonical-src'] = original_src
        end
        doc
      end

      def validate
        needs(:asset_proxy, :asset_proxy_secret_key) if asset_proxy_enabled?
      end

      def asset_host_allowed?(host)
        context[:asset_proxy_domain_regexp] ? context[:asset_proxy_domain_regexp].match?(host) : false
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
          Gitlab.config.asset_proxy['enabled']       = application_settings.asset_proxy_enabled
          Gitlab.config.asset_proxy['url']           = application_settings.asset_proxy_url
          Gitlab.config.asset_proxy['secret_key']    = application_settings.asset_proxy_secret_key
          Gitlab.config.asset_proxy['allowlist']     = determine_allowlist(application_settings)
          Gitlab.config.asset_proxy['domain_regexp'] = compile_allowlist(Gitlab.config.asset_proxy.allowlist)
        else
          Gitlab.config.asset_proxy['enabled']       = ::ApplicationSetting.defaults[:asset_proxy_enabled]
        end
      end

      def self.compile_allowlist(domain_list)
        return if domain_list.empty?

        escaped = domain_list.map { |domain| Regexp.escape(domain).gsub('\*', '.*?') }
        Regexp.new("^(#{escaped.join('|')})$", Regexp::IGNORECASE)
      end

      def self.determine_allowlist(application_settings)
        application_settings.try(:asset_proxy_allowlist).presence ||
          application_settings.try(:asset_proxy_whitelist).presence ||
          [Gitlab.config.gitlab.host]
      end

      private

      def asset_proxy_enabled?
        !context[:disable_asset_proxy]
      end

      def asset_proxy_url(url)
        "#{context[:asset_proxy]}/#{asset_url_hash(url)}/#{hexencode(url)}"
      end

      def asset_url_hash(url)
        OpenSSL::HMAC.hexdigest('sha1', context[:asset_proxy_secret_key], url)
      end

      def hexencode(str)
        str.unpack1('H*')
      end
    end
  end
end

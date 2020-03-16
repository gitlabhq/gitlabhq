# frozen_string_literal: true

# This is based on https://github.com/jch/html-pipeline/blob/v2.12.2/lib/html/pipeline/camo_filter.rb
# and Banzai::Filter::AssetProxyFilter which we use to proxy images in Markdown

module Gitlab
  module AssetProxy
    class << self
      def proxy_url(url)
        return url unless Gitlab.config.asset_proxy.enabled
        return url if asset_host_whitelisted?(url)

        "#{Gitlab.config.asset_proxy.url}/#{asset_url_hash(url)}/#{hexencode(url)}"
      rescue Addressable::URI::InvalidURIError
        url
      end

      private

      def asset_host_whitelisted?(url)
        parsed_url = Addressable::URI.parse(url)

        Gitlab.config.asset_proxy.domain_regexp&.match?(parsed_url.host)
      end

      def asset_url_hash(url)
        OpenSSL::HMAC.hexdigest('sha1', Gitlab.config.asset_proxy.secret_key, url)
      end

      def hexencode(str)
        str.unpack1('H*')
      end
    end
  end
end

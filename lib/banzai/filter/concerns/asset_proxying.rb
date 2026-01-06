# frozen_string_literal: true

module Banzai
  module Filter
    module Concerns
      module AssetProxying
        def validate_asset_proxying
          needs(:asset_proxy, :asset_proxy_secret_key) if asset_proxy_enabled?
        end

        def asset_proxy_enabled?
          # If nil (unset), don't enable automatically.
          # This will usually be set by `AssetProxyFilter.transform_context`, but some tests may
          # use filters that include AssetProxying without running AssetProxyFilter, and we don't
          # want them to assume it's being used and is configured when it isn't.
          context[:disable_asset_proxy] == false
        end

        def asset_proxy_url(url)
          "#{context[:asset_proxy]}/#{asset_url_hash(url)}/#{hexencode(url)}"
        end

        def can_skip_asset_proxy_for_url?(url)
          begin
            uri = URI.parse(url)
          rescue URI::Error
            return false
          else
            # Skip URLs like `/path.ext` or `path.ext` which are relative to the current host
            return true if uri.relative? && uri.host.nil? && url.match(%r{\A/*})[0].length < 2
            return true if asset_host_allowed?(uri.host)
          end

          false
        end

        private

        def asset_host_allowed?(host)
          context[:asset_proxy_domain_regexp] ? context[:asset_proxy_domain_regexp].match?(host) : false
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
end

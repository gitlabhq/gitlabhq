# frozen_string_literal: true

# Generated HTML is transformed back to GFM by app/assets/javascripts/behaviors/markdown/nodes/code_block.js
module Banzai
  module Filter
    class MermaidFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck
      include Concerns::AssetProxying
      include Gitlab::Utils::SanitizeNodeLink

      CSS   = 'pre[data-canonical-lang="mermaid"] > code'
      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS).freeze

      def call
        # When the asset proxy is enabled, we pre-generate asset proxy URLs for any URLs we find in
        # the source and pass them through to the frontend.  The frontend substitutes the asset proxy
        # URLs for any image srcs in the Mermaid result, dropping the image if there's no match --
        # i.e. we fail safe and don't load unproxied images.  This means we can sanitise an image from
        # Mermaid by just not including an asset proxy URL for it.  If we don't need to proxy the image,
        # we set the key to `true` to signal it's permitted.

        base_re = URI::DEFAULT_PARSER.make_regexp
        # Try to match surrounding single-quotes, such that the trailing one doesn't get included as
        # part of the path, query or fragment, as is permitted by the parser.  If we don't do this,
        # a URL in text like <img src='https://hello.com/wow.gif'> will match "https://hello.com/wow.gif'".
        uri_re = /(?<bare>#{base_re})|'(?<sq>#{base_re})'/

        doc.xpath(XPATH).each do |node|
          node.add_class('js-render-mermaid')

          next unless asset_proxy_enabled?

          proxied_urls = {}

          node.content.scan(uri_re) do
            uri = $~['bare'] || $~['sq']

            next unless permit_url?(uri)

            proxied_urls[uri] ||= can_skip_asset_proxy_for_url?(uri) ? true : asset_proxy_url(uri)
          end

          # The presence of data-proxied-urls indicates we should perform the image checks.
          # (If it's the empty object, '{}', that means all images should be removed!)
          node['data-proxied-urls'] = proxied_urls.to_json
        end

        doc
      end

      def validate
        validate_asset_proxying
      end
    end
  end
end

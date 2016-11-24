module Banzai
  module Filter
    # HTML Filter to modify the attributes of external links
    class ExternalLinkFilter < HTML::Pipeline::Filter
      def call
        links.each do |node|
          href = href_to_lowercase_scheme(node["href"].to_s)

          unless node["href"].to_s == href
            node.set_attribute('href', href)
          end

          if href =~ /\Ahttp(s)?:\/\// && external_url?(href)
            node.set_attribute('rel', 'nofollow noreferrer')
            node.set_attribute('target', '_blank')
          end
        end

        doc
      end

      private

      def links
        query = 'descendant-or-self::a[@href and not(@href = "")]'
        doc.xpath(query)
      end

      def href_to_lowercase_scheme(href)
        scheme_match = href.match(/\A(\w+):\/\//)

        if scheme_match
          scheme_match.to_s.downcase + scheme_match.post_match
        else
          href
        end
      end

      def external_url?(url)
        !url.start_with?(internal_url)
      end

      def internal_url
        @internal_url ||= Gitlab.config.gitlab.url
      end
    end
  end
end

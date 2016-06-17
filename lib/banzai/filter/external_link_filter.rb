module Banzai
  module Filter
    # HTML Filter to modify the attributes of external links
    class ExternalLinkFilter < HTML::Pipeline::Filter
      def call
        # Skip non-HTTP(S) links and internal links
        doc.xpath("descendant-or-self::a[starts-with(@href, 'http') and not(starts-with(@href, '#{internal_url}'))]").each do |node|
          node.set_attribute('rel', 'nofollow noreferrer')
          node.set_attribute('target', '_blank')
        end

        doc
      end

      private

      def internal_url
        @internal_url ||= Gitlab.config.gitlab.url
      end
    end
  end
end

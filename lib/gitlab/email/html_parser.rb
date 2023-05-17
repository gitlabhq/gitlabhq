# frozen_string_literal: true

module Gitlab
  module Email
    class HTMLParser
      def self.parse_reply(raw_body)
        new(raw_body).filtered_text
      end

      attr_reader :raw_body

      def initialize(raw_body)
        @raw_body = raw_body
      end

      def document
        @document ||= Nokogiri::HTML.parse(raw_body)
      end

      def filter_replies!
        # bogus links with no href are sometimes added by outlook,
        # and can result in Html2Text adding extra square brackets
        # to the text, so we unwrap them here.
        document.xpath('//a[not(@href)]').each do |link|
          link.replace(link.children)
        end
      end

      def filtered_html
        @filtered_html ||= begin
          filter_replies!
          document.inner_html
        end
      end

      def filtered_text
        @filtered_text ||= ::Gitlab::Email::HtmlToMarkdownParser.convert(filtered_html)
      end
    end
  end
end

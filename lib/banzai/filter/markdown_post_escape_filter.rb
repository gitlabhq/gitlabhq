# frozen_string_literal: true

module Banzai
  module Filter
    class MarkdownPostEscapeFilter < HTML::Pipeline::Filter
      LITERAL_KEYWORD   = MarkdownPreEscapeFilter::LITERAL_KEYWORD
      LITERAL_REGEX     = %r{#{LITERAL_KEYWORD}-(.*?)-#{LITERAL_KEYWORD}}.freeze
      NOT_LITERAL_REGEX = %r{#{LITERAL_KEYWORD}-((%5C|\\).+?)-#{LITERAL_KEYWORD}}.freeze
      SPAN_REGEX        = %r{<span>(.*?)</span>}.freeze

      CSS_A      = 'a'
      XPATH_A    = Gitlab::Utils::Nokogiri.css_to_xpath(CSS_A).freeze
      CSS_CODE   = 'code'
      XPATH_CODE = Gitlab::Utils::Nokogiri.css_to_xpath(CSS_CODE).freeze

      def call
        return doc unless result[:escaped_literals]

        # For any literals that actually didn't get escape processed
        # (for example in code blocks), remove the special sequence.
        html.gsub!(NOT_LITERAL_REGEX, '\1')

        # Replace any left over literal sequences with `span` so that our
        # reference processing is short-circuited
        html.gsub!(LITERAL_REGEX, '<span>\1</span>')

        # Since literals are converted in links, we need to remove any surrounding `span`.
        # Note: this could have been done in the renderer,
        # Banzai::Renderer::CommonMark::HTML.  However, we eventually want to use
        # the built-in compiled renderer, rather than the ruby version, for speed.
        # So let's do this work here.
        doc.xpath(XPATH_A).each do |node|
          node.attributes['href'].value  = node.attributes['href'].value.gsub(SPAN_REGEX, '\1') if node.attributes['href']
          node.attributes['title'].value = node.attributes['title'].value.gsub(SPAN_REGEX, '\1') if node.attributes['title']
        end

        doc.xpath(XPATH_CODE).each do |node|
          node.attributes['lang'].value  = node.attributes['lang'].value.gsub(SPAN_REGEX, '\1') if node.attributes['lang']
        end

        doc
      end
    end
  end
end

# frozen_string_literal: true

module Banzai
  module Filter
    class AsciiDocPostProcessingFilter < HTML::Pipeline::Filter
      CSS_MATH   = '[data-math-style]'
      XPATH_MATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS_MATH).freeze
      CSS_MERM   = '[data-mermaid-style]'
      XPATH_MERM = Gitlab::Utils::Nokogiri.css_to_xpath(CSS_MERM).freeze

      def call
        doc.xpath(XPATH_MATH).each do |node|
          node.set_attribute('class', 'code math js-render-math')
        end

        doc.xpath(XPATH_MERM).each do |node|
          node.set_attribute('class', 'js-render-mermaid')
        end

        doc
      end
    end
  end
end

# frozen_string_literal: true

# Generated HTML is transformed back to GFM by app/assets/javascripts/behaviors/markdown/nodes/code_block.js
module Banzai
  module Filter
    class SuggestionFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck
      include Concerns::ContextAccessors

      # Class used for tagging elements that should be rendered
      TAG_CLASS = 'js-render-suggestion'

      CSS   = 'pre.language-suggestion > code'
      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS).freeze

      def call
        return doc unless suggestions_filter_enabled?

        doc.xpath(XPATH).each do |node|
          node.add_class(TAG_CLASS)
        end

        doc
      end

      def suggestions_filter_enabled?
        context[:suggestions_filter_enabled]
      end
    end
  end
end

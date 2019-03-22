# frozen_string_literal: true

# Generated HTML is transformed back to GFM by app/assets/javascripts/behaviors/markdown/nodes/code_block.js
module Banzai
  module Filter
    class SuggestionFilter < HTML::Pipeline::Filter
      # Class used for tagging elements that should be rendered
      TAG_CLASS = 'js-render-suggestion'.freeze
      SUGGESTION_REGEX = Gitlab::Diff::SuggestionsParser::SUGGESTION_CONTEXT

      def call
        return doc unless suggestions_filter_enabled?

        doc.search('pre.suggestion > code').each do |node|
          # TODO: Remove once multi-line suggestions FF get removed (#59178).
          remove_multi_line_params(node.parent)

          node.add_class(TAG_CLASS)
        end

        doc
      end

      def suggestions_filter_enabled?
        context[:suggestions_filter_enabled]
      end

      private

      def project
        context[:project]
      end

      def remove_multi_line_params(node)
        return if Feature.enabled?(:multi_line_suggestions, project)

        if node[SyntaxHighlightFilter::LANG_PARAMS_ATTR]&.match?(SUGGESTION_REGEX)
          node.remove_attribute(SyntaxHighlightFilter::LANG_PARAMS_ATTR)
        end
      end
    end
  end
end

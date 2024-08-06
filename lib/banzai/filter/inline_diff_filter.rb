# frozen_string_literal: true

# Generated HTML is transformed back to GFM by app/assets/javascripts/behaviors/markdown/marks/inline_diff.js
module Banzai
  module Filter
    class InlineDiffFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck

      IGNORED_ANCESTOR_TAGS = %w[pre code tt].to_set

      INLINE_DIFF_DELETION_UNTRUSTED = '(?:\[\-(.*?)\-\]|\{\-(.*?)\-\})'
      INLINE_DIFF_DELETION_UNTRUSTED_REGEX =
        Gitlab::UntrustedRegexp.new(INLINE_DIFF_DELETION_UNTRUSTED, multiline: false).freeze

      INLINE_DIFF_ADDITION_UNTRUSTED = '(?:\[\+(.*?)\+\]|\{\+(.*?)\+\})'
      INLINE_DIFF_ADDITION_UNTRUSTED_REGEX =
        Gitlab::UntrustedRegexp.new(INLINE_DIFF_ADDITION_UNTRUSTED, multiline: false).freeze

      def call
        doc.xpath('descendant-or-self::text()').each do |node|
          next if has_ancestor?(node, IGNORED_ANCESTOR_TAGS)

          content = node.to_html
          html_content = inline_diff_filter(content)

          next if content == html_content

          node.replace(html_content)
        end
        doc
      end

      def inline_diff_filter(text)
        html_content = INLINE_DIFF_DELETION_UNTRUSTED_REGEX
          .replace_gsub(text, limit: Banzai::Filter::FILTER_ITEM_LIMIT) do |match|
          %(<span class="idiff left right deletion">#{match[1]}#{match[2]}</span>)
        end

        INLINE_DIFF_ADDITION_UNTRUSTED_REGEX
          .replace_gsub(html_content, limit: Banzai::Filter::FILTER_ITEM_LIMIT) do |match|
          %(<span class="idiff left right addition">#{match[1]}#{match[2]}</span>)
        end
      end
    end
  end
end

# frozen_string_literal: true

# Generated HTML is transformed back to GFM by:
# - app/assets/javascripts/behaviors/markdown/marks/math.js
# - app/assets/javascripts/behaviors/markdown/nodes/code_block.js
module Banzai
  module Filter
    # HTML filter that implements our dollar math syntax, one of three filters:
    # DollarMathPreFilter, DollarMathPostFilter, and MathFilter
    #
    class DollarMathPostFilter < HTML::Pipeline::Filter
      # Based on the Pandoc heuristics,
      # https://pandoc.org/MANUAL.html#extension-tex_math_dollars
      #
      # Handle the $...$ and $$...$$ inline syntax in this filter, after markdown processing
      # but before post-handling of escaped characters.  Any escaped $ will have been specially
      # encoded and will therefore not interfere with the detection of the dollar syntax.

      # Corresponds to the "$...$" syntax
      DOLLAR_INLINE_PATTERN = %r{
        (?<matched>\$(?<math>(?:\S[^$\n]*?\S|[^$\s]))\$)(?:[^\d]|$)
      }x.freeze

      # Corresponds to the "$$...$$" syntax
      DOLLAR_DISPLAY_INLINE_PATTERN = %r{
        (?<matched>\$\$\ *(?<math>[^$\n]+?)\ *\$\$)
      }x.freeze

      # Order dependent. Handle the `$$` syntax before the `$` syntax
      DOLLAR_MATH_PIPELINE = [
        { pattern: DOLLAR_DISPLAY_INLINE_PATTERN, style: :display },
        { pattern: DOLLAR_INLINE_PATTERN, style: :inline }
      ].freeze

      # Do not recognize math inside these tags
      IGNORED_ANCESTOR_TAGS = %w[pre code tt].to_set

      def call
        process_dollar_pipeline

        doc
      end

      def process_dollar_pipeline
        doc.xpath('descendant-or-self::text()').each do |node|
          next if has_ancestor?(node, IGNORED_ANCESTOR_TAGS)

          node_html = node.to_html
          next unless node_html.match?(DOLLAR_INLINE_PATTERN) ||
            node_html.match?(DOLLAR_DISPLAY_INLINE_PATTERN)

          temp_doc = Nokogiri::HTML.fragment(node_html)

          DOLLAR_MATH_PIPELINE.each do |pipeline|
            temp_doc.xpath('child::text()').each do |temp_node|
              html = temp_node.to_html
              temp_node.content.scan(pipeline[:pattern]).each do |matched, math|
                html.sub!(matched, math_html(math: math, style: pipeline[:style]))
              end

              temp_node.replace(html)
            end
          end

          node.replace(temp_doc)
        end
      end

      private

      def math_html(math:, style:)
        "<code data-math-style=\"#{style}\">#{math}</code>"
      end
    end
  end
end

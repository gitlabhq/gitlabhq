# frozen_string_literal: true

require 'uri'

# Generated HTML is transformed back to GFM by:
# - app/assets/javascripts/behaviors/markdown/marks/math.js
# - app/assets/javascripts/behaviors/markdown/nodes/code_block.js
module Banzai
  module Filter
    # HTML filter that implements our math syntax, adding class="code math"
    #
    class MathFilter < HTML::Pipeline::Filter
      CSS_MATH   = 'pre[lang="math"] > code'
      XPATH_MATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS_MATH).freeze
      CSS_CODE   = 'code'
      XPATH_CODE = Gitlab::Utils::Nokogiri.css_to_xpath(CSS_CODE).freeze

      # These are based on the Pandoc heuristics,
      # https://pandoc.org/MANUAL.html#extension-tex_math_dollars
      # Note: at this time, using a dollar sign literal, `\$` inside
      # a math statement does not work correctly.
      # Corresponds to the "$...$" syntax
      DOLLAR_INLINE_PATTERN = %r{
        (?<matched>\$(?<math>(?:\S[^$\n]*?\S|[^$\s]))\$)(?:[^\d]|$)
      }x.freeze

      # Corresponds to the "$$...$$" syntax
      DOLLAR_DISPLAY_INLINE_PATTERN = %r{
        (?<matched>\$\$\ *(?<math>[^$\n]+?)\ *\$\$)
      }x.freeze

      # Corresponds to the $$\n...\n$$ syntax
      DOLLAR_DISPLAY_BLOCK_PATTERN = %r{
        ^(?<matched>\$\$\ *\n(?<math>.*)\n\$\$\ *)$
      }mx.freeze

      # Order dependent. Handle the `$$` syntax before the `$` syntax
      DOLLAR_MATH_PIPELINE = [
        { pattern: DOLLAR_DISPLAY_INLINE_PATTERN, tag: :code, style: :display },
        { pattern: DOLLAR_DISPLAY_BLOCK_PATTERN, tag: :pre, style: :display },
        { pattern: DOLLAR_INLINE_PATTERN, tag: :code, style: :inline }
      ].freeze

      # Do not recognize math inside these tags
      IGNORED_ANCESTOR_TAGS = %w[pre code tt].to_set

      # Attribute indicating inline or display math.
      STYLE_ATTRIBUTE = 'data-math-style'

      # Class used for tagging elements that should be rendered
      TAG_CLASS = 'js-render-math'

      MATH_CLASSES = "code math #{TAG_CLASS}"
      DOLLAR_SIGN = '$'

      # Limit to how many nodes can be marked as math elements.
      # Prevents timeouts for large notes.
      # For more information check: https://gitlab.com/gitlab-org/gitlab/-/issues/341832
      RENDER_NODES_LIMIT = 50

      def call
        @nodes_count = 0

        process_dollar_pipeline

        process_dollar_backtick_inline
        process_math_codeblock

        doc
      end

      def process_dollar_pipeline
        doc.xpath('descendant-or-self::text()').each do |node|
          next if has_ancestor?(node, IGNORED_ANCESTOR_TAGS)

          node_html = node.to_html
          next unless node_html.match?(DOLLAR_INLINE_PATTERN) ||
            node_html.match?(DOLLAR_DISPLAY_INLINE_PATTERN) ||
            node_html.match?(DOLLAR_DISPLAY_BLOCK_PATTERN)

          temp_doc = Nokogiri::HTML.fragment(node_html)
          DOLLAR_MATH_PIPELINE.each do |pipeline|
            temp_doc.xpath('child::text()').each do |temp_node|
              html = temp_node.to_html
              temp_node.content.scan(pipeline[:pattern]).each do |matched, math|
                html.sub!(matched, math_html(tag: pipeline[:tag], style: pipeline[:style], math: math))

                @nodes_count += 1
                break if @nodes_count >= RENDER_NODES_LIMIT
              end

              temp_node.replace(html)

              break if @nodes_count >= RENDER_NODES_LIMIT
            end
          end

          node.replace(temp_doc)
        end
      end

      # Corresponds to the "$`...`$" syntax
      def process_dollar_backtick_inline
        doc.xpath(XPATH_CODE).each do |code|
          closing = code.next
          opening = code.previous

          # We need a sibling before and after.
          # They should end and start with $ respectively.
          next unless closing && opening &&
            closing.text? && opening.text? &&
            closing.content.first == DOLLAR_SIGN &&
            opening.content.last == DOLLAR_SIGN

          code[:class] = MATH_CLASSES
          code[STYLE_ATTRIBUTE] = 'inline'
          closing.content = closing.content[1..]
          opening.content = opening.content[0..-2]

          @nodes_count += 1
          break if @nodes_count >= RENDER_NODES_LIMIT
        end
      end

      # corresponds to the "```math...```" syntax
      def process_math_codeblock
        doc.xpath(XPATH_MATH).each do |node|
          pre_node = node.parent
          pre_node[STYLE_ATTRIBUTE] = 'display'
          pre_node[:class] = TAG_CLASS
        end
      end

      private

      def math_html(tag:, math:, style:)
        case tag
        when :code
          "<code class=\"#{MATH_CLASSES}\" data-math-style=\"#{style}\">#{math}</code>"
        when :pre
          "<pre class=\"#{MATH_CLASSES}\" data-math-style=\"#{style}\"><code>#{math}</code></pre>"
        end
      end

      def group
        context[:group] || context[:project]&.group
      end
    end
  end
end

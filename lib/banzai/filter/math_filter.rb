# frozen_string_literal: true

# Generated HTML is transformed back to GFM by:
# - app/assets/javascripts/behaviors/markdown/marks/math.js
# - app/assets/javascripts/behaviors/markdown/nodes/code_block.js
module Banzai
  module Filter
    # HTML filter that implements the original GitLab math syntax, one of three filters:
    # DollarMathPreFilter, DollarMathPostFilter, and MathFilter
    #
    class MathFilter < HTML::Pipeline::Filter
      # Handle the $`...`$ and ```math syntax in this filter.
      # Also add necessary classes any existing math blocks.
      prepend Concerns::PipelineTimingCheck
      include ::Gitlab::Utils::StrongMemoize

      CSS_MATH   = 'pre[data-canonical-lang="math"] > code'
      XPATH_MATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS_MATH).freeze
      CSS_CODE   = 'code'
      XPATH_CODE = Gitlab::Utils::Nokogiri.css_to_xpath(CSS_CODE).freeze
      CSS_INLINE_CODE = 'code[data-math-style]'
      XPATH_INLINE_CODE = Gitlab::Utils::Nokogiri.css_to_xpath(CSS_INLINE_CODE).freeze

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

        process_existing
        process_dollar_backtick_inline
        process_math_codeblock

        doc
      end

      private

      # Add necessary classes to any existing math blocks
      def process_existing
        doc.xpath(XPATH_INLINE_CODE).each do |code|
          break if render_nodes_limit_reached?(@nodes_count)

          code[:class] = MATH_CLASSES

          @nodes_count += 1
        end
      end

      # Corresponds to the "$`...`$" syntax
      def process_dollar_backtick_inline
        doc.xpath(XPATH_CODE).each do |code|
          break if render_nodes_limit_reached?(@nodes_count)

          closing = code.next
          opening = code.previous

          # We need a sibling before and after.
          # They should end and start with $ respectively.
          next unless closing && opening &&
            closing.text? && opening.text? &&
            closing.content.first == DOLLAR_SIGN &&
            opening.content.last == DOLLAR_SIGN

          code[STYLE_ATTRIBUTE] = 'inline'
          code[:class] = MATH_CLASSES
          closing.content = closing.content[1..]
          opening.content = opening.content[0..-2]

          @nodes_count += 1
        end
      end

      # Corresponds to the "```math...```" syntax
      def process_math_codeblock
        doc.xpath(XPATH_MATH).each do |node|
          pre_node = node.parent
          pre_node[STYLE_ATTRIBUTE] = 'display'
          pre_node[:class] = TAG_CLASS
        end
      end

      def render_nodes_limit_reached?(count)
        count >= RENDER_NODES_LIMIT && math_rendering_limits_enabled?
      end

      def math_rendering_limits_enabled?
        return true unless group && group.namespace_settings

        group.namespace_settings.math_rendering_limits_enabled?
      end
      strong_memoize_attr :math_rendering_limits_enabled?

      def group
        context[:project]&.parent || context[:group]
      end
    end
  end
end

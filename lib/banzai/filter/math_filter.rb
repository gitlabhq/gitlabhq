# frozen_string_literal: true

# TODO: Portions of this are legacy code, and is only used with the Ruby parser.
# The current markdown parser now properly handles math.
# The Ruby parser is now only for benchmarking purposes.
# issue: https://gitlab.com/gitlab-org/gitlab/-/issues/454601

# Generated HTML is transformed back to GFM by:
# - app/assets/javascripts/content_editor/extensions/math_inline.js
# - app/assets/javascripts/content_editor/extensions/code_block_highlight.js
module Banzai
  module Filter
    class MathFilter < HTML::Pipeline::Filter
      # HTML filter that adds any necessary classes to math html for rendering
      # on the frontend
      prepend Concerns::PipelineTimingCheck
      include ::Gitlab::Utils::StrongMemoize

      CSS_MATH_STYLE = 'pre[data-math-style], code[data-math-style], span[data-math-style]'
      XPATH_MATH_STYLE = Gitlab::Utils::Nokogiri.css_to_xpath(CSS_MATH_STYLE).freeze
      TAG_CLASS = 'js-render-math'

      # Limit to how many nodes can be marked as math elements.
      # Prevents timeouts for large notes.
      # For more information check: https://gitlab.com/gitlab-org/gitlab/-/issues/341832
      RENDER_NODES_LIMIT = 50

      def call
        @nodes_count = 0

        process_existing
        process_dollar_backtick_inline unless MarkdownFilter.glfm_markdown?(context)
        process_math_codeblock unless MarkdownFilter.glfm_markdown?(context)

        doc
      end

      private

      # Add necessary classes to existing math blocks
      def process_existing
        doc.xpath(XPATH_MATH_STYLE).each do |node|
          break if render_nodes_limit_reached?(@nodes_count)

          node[:class] = MarkdownFilter.glfm_markdown?(context) ? TAG_CLASS : MATH_CLASSES

          @nodes_count += 1
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

      #-----------------------------------------------------------------
      # TODO: Legacy code
      # issue: https://gitlab.com/gitlab-org/gitlab/-/issues/454601
      CSS_MATH   = 'pre[data-canonical-lang="math"] > code'
      XPATH_MATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS_MATH).freeze
      CSS_CODE   = 'code'
      XPATH_CODE = Gitlab::Utils::Nokogiri.css_to_xpath(CSS_CODE).freeze
      CSS_INLINE_CODE = 'code[data-math-style]'
      XPATH_INLINE_CODE = Gitlab::Utils::Nokogiri.css_to_xpath(CSS_INLINE_CODE).freeze

      # Attribute indicating inline or display math.
      STYLE_ATTRIBUTE = 'data-math-style'

      # Class used for tagging elements that should be rendered
      MATH_CLASSES = "code math #{TAG_CLASS}"
      DOLLAR_SIGN = '$'

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
    end
  end
end

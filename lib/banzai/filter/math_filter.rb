# frozen_string_literal: true

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
    end
  end
end

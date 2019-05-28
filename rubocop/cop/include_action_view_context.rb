# frozen_string_literal: true

require_relative '../spec_helpers'

module RuboCop
  module Cop
    # Cop that makes sure workers include `::Gitlab::ActionViewOutput::Context`, not `ActionView::Context`.
    class IncludeActionViewContext < RuboCop::Cop::Cop
      include SpecHelpers

      MSG = 'Include `::Gitlab::ActionViewOutput::Context`, not `ActionView::Context`, for Rails 5.'.freeze

      def_node_matcher :includes_action_view_context?, <<~PATTERN
        (send nil? :include (const (const nil? :ActionView) :Context))
      PATTERN

      def on_send(node)
        return if in_spec?(node)
        return unless includes_action_view_context?(node)

        add_offense(node.arguments.first, location: :expression)
      end

      def autocorrect(node)
        lambda do |corrector|
          corrector.replace(node.source_range, '::Gitlab::ActionViewOutput::Context')
        end
      end
    end
  end
end

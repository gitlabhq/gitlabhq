require_relative '../spec_helpers'

module RuboCop
  module Cop
    # Cop that makes sure workers include `ApplicationWorker`, not `Sidekiq::Worker`.
    class FullyQualifiedConstants < RuboCop::Cop::Cop
      include RuboCop::SpecHelpers

      MSG = 'Do not use unqualified constants (ex. Use `Gitlab::Util` instead of `Util`).'.freeze

      def_node_matcher :extend_include_prepend_bare?, <<~PATTERN
        (send nil? {:extend :include :prepend} #bare_constant?)
      PATTERN

      def_node_matcher :send_to_bare_constant?, <<~PATTERN
        (send #bare_constant? ...)
      PATTERN

      def_node_matcher :bare_constant?, <<~PATTERN
        (const nil? _)
      PATTERN

      def on_send(node)
        return if in_spec?(node)

        add_offense(node.arguments.first, location: :expression) if extend_include_prepend_bare?(node)
        add_offense(node, location: :expression) if send_to_bare_constant?(node)
      end
    end
  end
end

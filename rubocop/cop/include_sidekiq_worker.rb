require_relative '../spec_helpers'

module RuboCop
  module Cop
    # Cop that makes sure workers include `ApplicationWorker`, not `Sidekiq::Worker`.
    class IncludeSidekiqWorker < RuboCop::Cop::Cop
      include SpecHelpers

      MSG = 'Include `ApplicationWorker`, not `Sidekiq::Worker`.'.freeze

      def_node_matcher :includes_sidekiq_worker?, <<~PATTERN
        (send nil? :include (const (const nil? :Sidekiq) :Worker))
      PATTERN

      def on_send(node)
        return if in_spec?(node)
        return unless includes_sidekiq_worker?(node)

        add_offense(node.arguments.first, location: :expression)
      end

      def autocorrect(node)
        lambda do |corrector|
          corrector.replace(node.source_range, 'ApplicationWorker')
        end
      end
    end
  end
end

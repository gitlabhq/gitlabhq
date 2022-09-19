# frozen_string_literal: true

module RuboCop
  module Cop
    # Cop that makes sure workers include `ApplicationWorker`, not `Sidekiq::Worker`.
    class IncludeSidekiqWorker < RuboCop::Cop::Base
      extend RuboCop::Cop::AutoCorrector

      MSG = 'Include `ApplicationWorker`, not `Sidekiq::Worker`.'

      def_node_matcher :includes_sidekiq_worker?, <<~PATTERN
        (send nil? :include (const (const nil? :Sidekiq) :Worker))
      PATTERN

      def on_send(node)
        return unless includes_sidekiq_worker?(node)

        add_offense(node.arguments.first) do |corrector|
          corrector.replace(node.arguments.first, 'ApplicationWorker')
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative '../code_reuse_helpers'

module RuboCop
  module Cop
    # This cop checks for a call to `data_consistency` to exist in Sidekiq workers.
    #
    # @example
    #
    # # bad
    # class BadWorker
    #   def perform
    #   end
    # end
    #
    # # good
    # class GoodWorker
    #   data_consistency :delayed
    #
    #   def perform
    #   end
    # end
    #
    class WorkerDataConsistency < RuboCop::Cop::Cop
      include CodeReuseHelpers

      HELP_LINK = 'https://docs.gitlab.com/ee/development/sidekiq_style_guide.html#job-data-consistency-strategies'

      MSG = <<~MSG
        Should define data_consistency expectation.

        It is encouraged for workers to use database replicas as much as possible by declaring
        data_consistency to use the :delayed or :sticky modes. Mode :always will result in the
        worker always hitting the primary database node for both reads and writes, which limits
        scalability.

        Some guidelines:
        
        1. If your worker mostly writes or reads its own writes, use mode :always. TRY TO AVOID THIS.
        2. If your worker performs mostly reads and can tolerate small delays, use mode :delayed.
        3. If your worker performs mostly reads but cannot tolerate any delays, use mode :sticky.

        See #{HELP_LINK} for a more detailed explanation of these settings.
      MSG

      def_node_search :application_worker?, <<~PATTERN
      `(send nil? :include (const nil? :ApplicationWorker))
      PATTERN

      def_node_search :data_consistency_defined?, <<~PATTERN
        `(send nil? :data_consistency ...)
      PATTERN

      def on_class(node)
        return unless in_worker?(node) && application_worker?(node)
        return if data_consistency_defined?(node)

        add_offense(node, location: :expression)
      end
    end
  end
end

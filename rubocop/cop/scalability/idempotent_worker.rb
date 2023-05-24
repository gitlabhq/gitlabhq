# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module Scalability
      # This cop checks for the `idempotent!` call in the worker scope.
      #
      # @example
      #
      # # bad
      # class TroubleMakerWorker
      #   def perform
      #   end
      # end
      #
      # # good
      # class NiceWorker
      #   idempotent!
      #
      #   def perform
      #   end
      # end
      #
      class IdempotentWorker < RuboCop::Cop::Base
        include CodeReuseHelpers

        HELP_LINK = 'https://github.com/mperham/sidekiq/wiki/Best-Practices#2-make-your-job-idempotent-and-transactional'

        MSG = <<~MSG.freeze
          Avoid adding not idempotent workers.

          A worker is considered idempotent if:

          1. It can safely run multiple times with the same arguments
          2. The application side-effects are expected to happen once (or side-effects of a second run are not impactful)
          3. It can safely be skipped if another job with the same arguments is already in the queue

          If all the above is true, make sure to mark it as so by calling the `idempotent!`
          method in the worker scope.

          See #{HELP_LINK}
        MSG

        def_node_search :idempotent?, <<~PATTERN
          (send nil? :idempotent!)
        PATTERN

        def on_class(node)
          return unless in_worker?(node)
          return if idempotent?(node)

          add_offense(node)
        end
      end
    end
  end
end

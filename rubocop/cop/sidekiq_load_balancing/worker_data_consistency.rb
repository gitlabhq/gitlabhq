# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module SidekiqLoadBalancing
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
      class WorkerDataConsistency < RuboCop::Cop::Base
        include CodeReuseHelpers

        HELP_LINK = 'https://docs.gitlab.com/ee/development/sidekiq/worker_attributes.html#job-data-consistency-strategies'

        MISSING_DATA_CONSISTENCY_MSG = <<~MSG.freeze
          Should define data_consistency expectation.
          See #{HELP_LINK} for a more detailed explanation of these settings.
        MSG

        DISCOURAGE_ALWAYS_MSG = "Refrain from using `:always` if possible." \
                                "See #{HELP_LINK} for a more detailed explanation of these settings.".freeze

        def_node_search :application_worker?, <<~PATTERN
        `(send nil? :include (const nil? :ApplicationWorker))
        PATTERN

        def_node_matcher :data_consistency_value, <<~PATTERN
          `(send nil? :data_consistency $(sym _) ...)
        PATTERN

        def on_class(node)
          return unless application_worker?(node)

          consistency = data_consistency_value(node)
          return add_offense(node, message: MISSING_DATA_CONSISTENCY_MSG) if consistency.nil?

          add_offense(consistency, message: DISCOURAGE_ALWAYS_MSG) if consistency.value == :always
        end
      end
    end
  end
end

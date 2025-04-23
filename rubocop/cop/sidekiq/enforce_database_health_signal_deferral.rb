# frozen_string_literal: true

module RuboCop
  module Cop
    module Sidekiq
      # This cop enforces the use of `defer_on_database_health_signal` for low urgency workers
      #
      # @example
      #
      #   # bad
      #   module Workers
      #     class MyWorker
      #       include ApplicationWorker
      #
      #       urgency :low
      #     end
      #   end
      #
      #   # good
      #   module Workers
      #     class MyWorker
      #       include ApplicationWorker
      #
      #       urgency :low
      #       defer_on_database_health_signal :gitlab_main, [:users], 2.minutes
      #     end
      #   end
      class EnforceDatabaseHealthSignalDeferral < RuboCop::Cop::Base
        URL = 'https://docs.gitlab.com/development/sidekiq/#deferring-sidekiq-workers'
        MSG = "Low urgency workers should have the option to be deferred based on the database health condition. " \
          "Consider using `defer_on_database_health_signal`, check #{URL} for more information.".freeze

        # @!method low_urgency?(node)
        def_node_matcher :low_urgency?, <<~PATTERN
          `(send nil? :urgency (sym :low) ...)
        PATTERN

        # @!method defers_on_database_health_signal?(node)
        def_node_matcher :defers_on_database_health_signal?, <<~PATTERN
          `(send nil? :defer_on_database_health_signal ...)
        PATTERN

        def on_class(node)
          return unless low_urgency?(node)

          return if defers_on_database_health_signal?(node)

          add_offense(node)
        end
      end
    end
  end
end

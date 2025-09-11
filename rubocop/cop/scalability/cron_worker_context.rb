# frozen_string_literal: true

module RuboCop
  module Cop
    module Scalability
      # Ensures that workers scheduled via the `CronjobQueue` include contextual
      # metadata by either calling `with_context` or using bulk scheduling with context.
      # Context is used for logging and traceability of cron jobs.
      #
      # @example
      #   # bad
      #   class MyCronWorker
      #     include CronjobQueue
      #
      #     def perform
      #       # no context provided
      #     end
      #   end
      #
      #   # good
      #   class MyCronWorker
      #     include CronjobQueue
      #
      #     def perform
      #       with_context(project: project) do
      #         # work here
      #       end
      #     end
      #   end
      #
      #   # good (batch context)
      #   SomeWorker.bulk_perform_async_with_contexts([[1], [2]], { project: project })
      class CronWorkerContext < RuboCop::Cop::Base
        MSG = <<~MSG
          Manually define an ApplicationContext for cronjob-workers. The context
          is required to add metadata to our logs.

          If there is no relevant metadata, please disable the cop with a comment
          explaining this.

          Read more about it https://docs.gitlab.com/ee/development/sidekiq/logging.html#worker-context
        MSG

        # @!method includes_cronjob_queue?(node)
        def_node_matcher :includes_cronjob_queue?, <<~PATTERN
          (send nil? :include (const nil? :CronjobQueue))
        PATTERN

        # @!method defines_contexts?(node)
        def_node_search :defines_contexts?, <<~PATTERN
         (send nil? :with_context _)
        PATTERN

        # @!method schedules_with_batch_context?(node)
        def_node_search :schedules_with_batch_context?, <<~PATTERN
          (send (...) {:bulk_perform_async_with_contexts :bulk_perform_in_with_contexts} _*)
        PATTERN

        def on_send(node)
          return unless includes_cronjob_queue?(node)
          return if defines_contexts?(node.parent)
          return if schedules_with_batch_context?(node.parent)

          add_offense(node.first_argument)
        end
      end
    end
  end
end

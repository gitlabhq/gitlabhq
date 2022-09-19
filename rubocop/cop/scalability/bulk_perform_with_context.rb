# frozen_string_literal: true

require_relative '../../migration_helpers'
require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module Scalability
      class BulkPerformWithContext < RuboCop::Cop::Base
        include RuboCop::MigrationHelpers
        include RuboCop::CodeReuseHelpers

        MSG = <<~MSG
          Prefer using `Worker.bulk_perform_async_with_contexts` and
          `Worker.bulk_perform_in_with_context` over the methods without a context
          if your worker deals with specific projects or namespaces
          The context is required to add metadata to our logs.

          If there is already a parent context that will apply to the jobs
          being scheduled, please disable this cop with a comment explaing which
          context will be applied.

          Read more about it https://docs.gitlab.com/ee/development/sidekiq/logging.html#worker-context
        MSG

        BACKGROUND_MIGRATION_WORKER_NAMES = %w[BackgroundMigrationWorker CiDatabaseWorker].freeze

        def_node_matcher :schedules_in_batch_without_context?, <<~PATTERN
          (send (...) {:bulk_perform_async :bulk_perform_in} _*)
        PATTERN

        def on_send(node)
          return if in_migration?(node) || in_spec?(node)
          return unless schedules_in_batch_without_context?(node)
          return if scheduled_for_background_migration?(node)

          add_offense(node)
        end

        private

        def in_spec?(node)
          file_path_for_node(node).end_with?("_spec.rb")
        end

        def scheduled_for_background_migration?(node)
          BACKGROUND_MIGRATION_WORKER_NAMES.include?(name_of_receiver(node))
        end
      end
    end
  end
end

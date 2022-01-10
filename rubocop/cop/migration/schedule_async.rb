# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      class ScheduleAsync < RuboCop::Cop::Cop
        include MigrationHelpers

        ENFORCED_SINCE = 2020_02_12_00_00_00

        MSG = <<~MSG
          Don't call the background migration worker directly, use the `#migrate_in` or
          `#queue_background_migration_jobs_by_range_at_intervals` migration helpers instead.
        MSG

        def_node_matcher :calls_background_migration_worker?, <<~PATTERN
          (send (const nil? :BackgroundMigrationWorker) {:perform_async :perform_in :bulk_perform_async :bulk_perform_in} ... )
        PATTERN

        def on_send(node)
          return unless in_migration?(node)
          return if version(node) < ENFORCED_SINCE

          add_offense(node, location: :expression) if calls_background_migration_worker?(node)
        end
      end
    end
  end
end

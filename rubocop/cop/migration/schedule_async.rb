# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      class ScheduleAsync < RuboCop::Cop::Base
        include MigrationHelpers

        ENFORCED_SINCE = 2020_02_12_00_00_00

        MSG = <<~MSG
          Don't call the background migration worker directly, use the `#migrate_in` or
          `#queue_background_migration_jobs_by_range_at_intervals` migration helpers instead.
        MSG

        def_node_matcher :calls_background_migration_worker?, <<~PATTERN
          (send (const {cbase nil?} :BackgroundMigrationWorker) #perform_method? ...)
        PATTERN

        def_node_matcher :calls_ci_database_worker?, <<~PATTERN
          (send (const {(const {cbase nil?} :BackgroundMigration) nil?} :CiDatabaseWorker) #perform_method? ...)
        PATTERN

        def_node_matcher :perform_method?, <<~PATTERN
          {:perform_async :bulk_perform_async :perform_in :bulk_perform_in}
        PATTERN

        def on_send(node)
          return unless in_migration?(node)
          return if version(node) < ENFORCED_SINCE
          return unless calls_background_migration_worker?(node) || calls_ci_database_worker?(node)

          add_offense(node)
        end
      end
    end
  end
end

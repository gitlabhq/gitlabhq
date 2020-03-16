# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      class ScheduleAsync < RuboCop::Cop::Cop
        include MigrationHelpers

        ENFORCED_SINCE = 2020_02_12_00_00_00

        MSG = <<~MSG
          Don't call the background migration worker directly, use the `#migrate_async`,
          `#migrate_in`, `#bulk_migrate_async` or `#bulk_migrate_in` migration helpers
          instead.
        MSG

        def_node_matcher :calls_background_migration_worker?, <<~PATTERN
          (send (const nil? :BackgroundMigrationWorker) {:perform_async :perform_in :bulk_perform_async :bulk_perform_in} ... )
        PATTERN

        def on_send(node)
          return unless in_migration?(node)
          return if version(node) < ENFORCED_SINCE

          add_offense(node, location: :expression) if calls_background_migration_worker?(node)
        end

        def autocorrect(node)
          # This gets rid of the receiver `BackgroundMigrationWorker` and
          # replaces `perform` with `schedule`
          schedule_method = method_name(node).to_s.sub('perform', 'migrate')
          arguments = arguments(node).map(&:source).join(', ')

          replacement = "#{schedule_method}(#{arguments})"
          lambda do |corrector|
            corrector.replace(node.source_range, replacement)
          end
        end

        private

        def method_name(node)
          node.children.second
        end

        def arguments(node)
          node.children[2..-1]
        end
      end
    end
  end
end

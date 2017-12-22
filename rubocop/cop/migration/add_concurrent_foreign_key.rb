require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks if `add_concurrent_foreign_key` is used instead of
      # `add_foreign_key`.
      class AddConcurrentForeignKey < RuboCop::Cop::Cop
        include MigrationHelpers

        MSG = '`add_foreign_key` requires downtime, use `add_concurrent_foreign_key` instead'.freeze

        def on_send(node)
          return unless in_migration?(node)

          name = node.children[1]

          add_offense(node, location: :selector) if name == :add_foreign_key
        end

        def method_name(node)
          node.children.first
        end
      end
    end
  end
end

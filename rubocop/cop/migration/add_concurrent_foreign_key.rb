require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks if `add_concurrent_foreign_key` is used instead of
      # `add_foreign_key`.
      class AddConcurrentForeignKey < RuboCop::Cop::Cop
        include MigrationHelpers

        MSG = '`add_foreign_key` requires downtime, use `add_concurrent_foreign_key` instead'.freeze

        def_node_matcher :false_node?, <<~PATTERN
        (false)
        PATTERN

        def on_send(node)
          return unless in_migration?(node)

          name = node.children[1]

          if name == :add_foreign_key && !not_valid_fk?(node)
            add_offense(node, location: :selector)
          end
        end

        def method_name(node)
          node.children.first
        end

        def not_valid_fk?(node)
          node.each_node(:pair).any? do |pair|
            pair.children[0].children[0] == :validate && false_node?(pair.children[1])
          end
        end
      end
    end
  end
end

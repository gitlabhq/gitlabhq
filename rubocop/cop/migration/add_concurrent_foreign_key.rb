# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks if `add_concurrent_foreign_key` is used instead of
      # `add_foreign_key`.
      class AddConcurrentForeignKey < RuboCop::Cop::Cop
        include MigrationHelpers

        MSG = '`add_foreign_key` requires downtime, use `add_concurrent_foreign_key` instead'

        def_node_matcher :false_node?, <<~PATTERN
          (false)
        PATTERN

        def_node_matcher :with_lock_retries?, <<~PATTERN
          (:send nil? :with_lock_retries)
        PATTERN

        def on_send(node)
          return unless in_migration?(node)

          name = node.children[1]

          return unless name == :add_foreign_key
          return if in_with_lock_retries?(node)
          return if not_valid_fk?(node)

          add_offense(node, location: :selector)
        end

        def method_name(node)
          node.children.first
        end

        def not_valid_fk?(node)
          node.each_node(:pair).any? do |pair|
            pair.children[0].children[0] == :validate && false_node?(pair.children[1])
          end
        end

        def in_with_lock_retries?(node)
          node.each_ancestor(:block).any? do |parent|
            with_lock_retries?(parent.to_a.first)
          end
        end
      end
    end
  end
end

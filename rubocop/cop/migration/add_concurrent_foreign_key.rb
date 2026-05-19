# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks if `add_concurrent_foreign_key` is used instead of
      # `add_foreign_key`.
      class AddConcurrentForeignKey < RuboCop::Cop::Base
        include MigrationHelpers

        RESTRICT_ON_SEND = %i[add_foreign_key].freeze
        MSG = '`add_foreign_key` requires downtime, use `add_concurrent_foreign_key` instead'

        # @!method false_node?(node)
        def_node_matcher :false_node?, <<~PATTERN
          (false)
        PATTERN

        # @!method with_lock_retries?(node)
        def_node_matcher :with_lock_retries?, <<~PATTERN
          (:send nil? :with_lock_retries)
        PATTERN

        def on_send(node)
          return unless in_migration?(node)
          return if in_with_lock_retries?(node)
          return if not_valid_fk?(node)

          add_offense(node.loc.selector)
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

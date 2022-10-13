# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks `ActiveSupport::Concern` is included in EE batched background migrations
      # if they define `scope_to`.
      class BackgroundMigrationMissingActiveConcern < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = <<~MSG
          Extend `ActiveSupport::Concern` in the EE background migration if it defines `scope_to`.
        MSG

        def_node_matcher :prepended_block_uses_scope_to?, <<~PATTERN
          (:block (:send nil? :prepended) (:args) `(:send nil? :scope_to ...))
        PATTERN

        def_node_matcher :scope_to?, <<~PATTERN
          (:send nil? :scope_to ...)
        PATTERN

        def_node_matcher :extend_activesupport_concern?, <<~PATTERN
          (:send nil? :extend (:const (:const nil? :ActiveSupport) :Concern))
        PATTERN

        def on_block(node)
          return unless in_ee_background_migration?(node)
          return unless prepended_block_uses_scope_to?(node)

          return if module_extends_activesupport_concern?(node)

          node.descendants.each do |descendant|
            next unless scope_to?(descendant)

            add_offense(descendant)
          end
        end

        private

        def module_extends_activesupport_concern?(node)
          while node = node.parent
            break if node.type == :module
          end

          return false unless node

          node.descendants.any? do |descendant|
            extend_activesupport_concern?(descendant)
          end
        end
      end
    end
  end
end

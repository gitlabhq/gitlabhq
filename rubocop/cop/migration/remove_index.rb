# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks if indexes are removed in a concurrent manner.
      class RemoveIndex < RuboCop::Cop::Cop
        include MigrationHelpers

        MSG = '`remove_index` requires downtime, use `remove_concurrent_index` instead'

        def on_def(node)
          return unless in_migration?(node)

          node.each_descendant(:send) do |send_node|
            add_offense(send_node, location: :selector) if method_name(send_node) == :remove_index
          end
        end

        def method_name(node)
          node.children[1]
        end
      end
    end
  end
end

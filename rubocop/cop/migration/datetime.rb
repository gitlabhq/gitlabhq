require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks if datetime data type is added with timezone information.
      class Datetime < RuboCop::Cop::Cop
        include MigrationHelpers

        MSG = 'Do not use the `datetime` data type, use `datetime_with_timezone` instead'.freeze

        # Check methods in table creation.
        def on_def(node)
          return unless in_migration?(node)

          node.each_descendant(:send) do |send_node|
            add_offense(send_node, :selector) if method_name(send_node) == :datetime
          end
        end

        # Check methods.
        def on_send(node)
          return unless in_migration?(node)

          node.each_descendant do |descendant|
            add_offense(node, :expression) if descendant.type == :sym && descendant.children.last == :datetime
          end
        end

        def method_name(node)
          node.children[1]
        end
      end
    end
  end
end

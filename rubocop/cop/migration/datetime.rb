require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks if datetime data type is added with timezone information.
      class Datetime < RuboCop::Cop::Cop
        include MigrationHelpers

        MSG = 'Do not use the `%s` data type, use `datetime_with_timezone` instead'.freeze

        # Check methods in table creation.
        def on_def(node)
          return unless in_migration?(node)

          node.each_descendant(:send) do |send_node|
            method_name = node.children[1]

            if method_name == :datetime || method_name == :timestamp
              add_offense(send_node, location: :selector, message: format(MSG, method_name))
            end
          end
        end

        # Check methods.
        def on_send(node)
          return unless in_migration?(node)

          node.each_descendant do |descendant|
            next unless descendant.type == :sym

            last_argument = descendant.children.last

            if last_argument == :datetime || last_argument == :timestamp
              add_offense(node, location: :expression, message: format(MSG, last_argument))
            end
          end
        end
      end
    end
  end
end

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks if 'timestamps' method is called with timezone information.
      class Timestamps < RuboCop::Cop::Cop
        include MigrationHelpers

        MSG = 'Do not use `timestamps`, use `timestamps_with_timezone` instead'.freeze

        # Check methods in table creation.
        def on_def(node)
          return unless in_migration?(node)

          node.each_descendant(:send) do |send_node|
            add_offense(send_node, location: :selector) if method_name(send_node) == :timestamps
          end
        end

        def method_name(node)
          node.children[1]
        end
      end
    end
  end
end

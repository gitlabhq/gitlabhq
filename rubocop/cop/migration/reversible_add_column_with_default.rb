require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks if `add_column_with_default` is used with `up`/`down` methods
      # and not `change`.
      class ReversibleAddColumnWithDefault < RuboCop::Cop::Cop
        include MigrationHelpers

        def_node_matcher :add_column_with_default?, <<~PATTERN
          (send nil? :add_column_with_default $...)
        PATTERN

        def_node_matcher :defines_change?, <<~PATTERN
          (def :change ...)
        PATTERN

        MSG = '`add_column_with_default` is not reversible so you must manually define ' \
          'the `up` and `down` methods in your migration class, using `remove_column` in `down`'.freeze

        def on_send(node)
          return unless in_migration?(node)
          return unless add_column_with_default?(node)

          node.each_ancestor(:def) do |def_node|
            next unless defines_change?(def_node)

            add_offense(def_node, location: :name)
          end
        end
      end
    end
  end
end

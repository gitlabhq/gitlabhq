require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks if `add_concurrent_index` is used with `up`/`down` methods
      # and not `change`.
      class AddConcurrentIndex < RuboCop::Cop::Cop
        include MigrationHelpers

        MSG = '`add_concurrent_index` is not reversible so you must manually define ' \
          'the `up` and `down` methods in your migration class, using `remove_concurrent_index` in `down`'.freeze

        def on_send(node)
          return unless in_migration?(node)

          name = node.children[1]

          return unless name == :add_concurrent_index

          node.each_ancestor(:def) do |def_node|
            next unless method_name(def_node) == :change

            add_offense(def_node, location: :name)
          end
        end

        def method_name(node)
          node.children.first
        end
      end
    end
  end
end

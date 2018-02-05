require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks if `remove_concurrent_index` is used with `up`/`down` methods
      # and not `change`.
      class RemoveConcurrentIndex < RuboCop::Cop::Cop
        include MigrationHelpers

        MSG = '`remove_concurrent_index` is not reversible so you must manually define ' \
          'the `up` and `down` methods in your migration class, using `add_concurrent_index` in `down`'.freeze

        def on_send(node)
          return unless in_migration?(node)
          return unless node.children[1] == :remove_concurrent_index

          node.each_ancestor(:def) do |def_node|
            add_offense(def_node, location: :name) if method_name(def_node) == :change
          end
        end

        def method_name(node)
          node.children[0]
        end
      end
    end
  end
end

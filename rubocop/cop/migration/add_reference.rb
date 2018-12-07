# frozen_string_literal: true
require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks if a foreign key constraint is added and require a index for it
      class AddReference < RuboCop::Cop::Cop
        include MigrationHelpers

        MSG = '`add_reference` requires `index: true` or `index: { options... }`'

        def on_send(node)
          return unless in_migration?(node)

          name = node.children[1]

          return unless name == :add_reference

          opts = node.children.last

          add_offense(node, location: :selector) unless opts && opts.type == :hash

          index_present = false

          opts.each_node(:pair) do |pair|
            index_present ||= index_enabled?(pair)
          end

          add_offense(node, location: :selector) unless index_present
        end

        private

        def index_enabled?(pair)
          return unless hash_key_type(pair) == :sym
          return unless hash_key_name(pair) == :index

          index = pair.children[1]

          index.true_type? || index.hash_type?
        end

        def hash_key_type(pair)
          pair.children[0].type
        end

        def hash_key_name(pair)
          pair.children[0].children[0]
        end
      end
    end
  end
end

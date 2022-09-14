# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      class ComplexIndexesRequireName < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = 'indexes added with custom options must be explicitly named'

        def_node_matcher :match_create_table_index_with_options, <<~PATTERN
          (send _ {:index } _ (hash $...))
        PATTERN

        def_node_matcher :match_add_index_with_options, <<~PATTERN
          (send _ {:add_index :add_concurrent_index} _ _ (hash $...))
        PATTERN

        def_node_matcher :name_option?, <<~PATTERN
          (pair {(sym :name) (str "name")} _)
        PATTERN

        def_node_matcher :unique_option?, <<~PATTERN
          (pair {(:sym :unique) (str "unique")} _)
        PATTERN

        def on_def(node)
          return unless in_migration?(node)

          node.each_descendant(:send) do |send_node|
            next unless create_table_with_index_offense?(send_node) || add_index_offense?(send_node)

            add_offense(send_node.loc.selector)
          end
        end

        private

        def create_table_with_index_offense?(send_node)
          match_create_table_index_with_options(send_node) { |option_nodes| needs_name_option?(option_nodes) }
        end

        def add_index_offense?(send_node)
          match_add_index_with_options(send_node) { |option_nodes| needs_name_option?(option_nodes) }
        end

        def needs_name_option?(option_nodes)
          return false if only_unique_option?(option_nodes)

          option_nodes.none? { |node| name_option?(node) }
        end

        def only_unique_option?(option_nodes)
          option_nodes.size == 1 && unique_option?(option_nodes.first)
        end
      end
    end
  end
end

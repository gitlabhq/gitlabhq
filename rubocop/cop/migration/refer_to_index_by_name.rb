# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      class ReferToIndexByName < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = 'migration methods that refer to existing indexes must do so by name'

        def_node_matcher :match_index_exists, <<~PATTERN
          (send _ :index_exists? _ _ (hash $...) ?)
        PATTERN

        def_node_matcher :match_remove_index, <<~PATTERN
          (send _ :remove_index _ $_)
        PATTERN

        def_node_matcher :match_remove_concurrent_index, <<~PATTERN
          (send _ :remove_concurrent_index _ _ (hash $...) ?)
        PATTERN

        def_node_matcher :name_option?, <<~PATTERN
          (pair {(sym :name) (str "name")} _)
        PATTERN

        def on_def(node)
          return unless in_migration?(node)

          node.each_descendant(:send) do |send_node|
            next unless index_exists_offense?(send_node) || removing_index_offense?(send_node)

            add_offense(send_node.loc.selector)
          end
        end

        private

        def index_exists_offense?(send_node)
          match_index_exists(send_node) { |option_nodes| needs_name_option?(option_nodes) }
        end

        def removing_index_offense?(send_node)
          remove_index_offense?(send_node) || remove_concurrent_index_offense?(send_node)
        end

        def remove_index_offense?(send_node)
          match_remove_index(send_node) do |column_or_options_node|
            break true unless column_or_options_node.type == :hash

            column_or_options_node.children.none? { |pair| name_option?(pair) }
          end
        end

        def remove_concurrent_index_offense?(send_node)
          match_remove_concurrent_index(send_node) { |option_nodes| needs_name_option?(option_nodes) }
        end

        def needs_name_option?(option_nodes)
          option_nodes.empty? || option_nodes.first.none? { |node| name_option?(node) }
        end
      end
    end
  end
end

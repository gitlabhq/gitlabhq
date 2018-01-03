require 'set'
require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that prevents the use of hash indexes in database migrations
      class HashIndex < RuboCop::Cop::Cop
        include MigrationHelpers

        MSG = 'hash indexes should be avoided at all costs since they are not ' \
          'recorded in the PostgreSQL WAL, you should use a btree index instead'.freeze

        NAMES = Set.new([:add_index, :index, :add_concurrent_index]).freeze

        def on_send(node)
          return unless in_migration?(node)

          name = node.children[1]

          return unless NAMES.include?(name)

          opts = node.children.last

          return unless opts && opts.type == :hash

          opts.each_node(:pair) do |pair|
            next unless hash_key_type(pair) == :sym &&
                hash_key_name(pair) == :using

            if hash_key_value(pair).to_s == 'hash'
              add_offense(pair, location: :expression)
            end
          end
        end

        def hash_key_type(pair)
          pair.children[0].type
        end

        def hash_key_name(pair)
          pair.children[0].children[0]
        end

        def hash_key_value(pair)
          pair.children[1].children[0]
        end
      end
    end
  end
end

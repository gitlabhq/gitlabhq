require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks if columns are added in a way that doesn't require
      # downtime.
      class AddColumn < RuboCop::Cop::Cop
        include MigrationHelpers

        WHITELISTED_TABLES = %i[
          application_settings
          plan_limits
        ].freeze

        MSG = '`add_column` with a default value requires downtime, ' \
          'use `add_column_with_default` instead'.freeze

        def on_send(node)
          return unless in_migration?(node)

          name = node.children[1]

          return unless name == :add_column

          # Ignore whitelisted tables.
          return if table_whitelisted?(node.children[2])

          opts = node.children.last

          return unless opts && opts.type == :hash

          opts.each_node(:pair) do |pair|
            if hash_key_type(pair) == :sym && hash_key_name(pair) == :default
              add_offense(node, location: :selector)
            end
          end
        end

        def table_whitelisted?(symbol)
          symbol && symbol.type == :sym &&
            WHITELISTED_TABLES.include?(symbol.children[0])
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

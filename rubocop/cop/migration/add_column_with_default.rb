# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that checks if columns are added in a way that doesn't require
      # downtime.
      class AddColumnWithDefault < RuboCop::Cop::Cop
        include MigrationHelpers

        WHITELISTED_TABLES = [:application_settings].freeze

        MSG = '`add_column_with_default` with `allow_null: false` may cause prolonged lock situations and downtime, ' \
          'see https://gitlab.com/gitlab-org/gitlab/issues/38060'.freeze

        def on_send(node)
          return unless in_migration?(node)

          name = node.children[1]

          return unless name == :add_column_with_default

          # Ignore whitelisted tables.
          return if table_whitelisted?(node.children[2])

          opts = node.children.last

          return unless opts && opts.type == :hash

          opts.each_node(:pair) do |pair|
            if disallows_null_values?(pair)
              add_offense(node, location: :selector)
            end
          end
        end

        def table_whitelisted?(symbol)
          symbol && symbol.type == :sym &&
            WHITELISTED_TABLES.include?(symbol.children[0])
        end

        def disallows_null_values?(pair)
          options = [hash_key_type(pair), hash_key_name(pair), hash_value(pair)]

          options == [:sym, :allow_null, :false] # rubocop:disable Lint/BooleanSymbol
        end

        def hash_key_type(pair)
          pair.children[0].type
        end

        def hash_key_name(pair)
          pair.children[0].children[0]
        end

        def hash_value(pair)
          pair.children[1].type
        end
      end
    end
  end
end

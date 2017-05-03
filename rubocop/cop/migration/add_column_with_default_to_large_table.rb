require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # This cop checks for `add_column_with_default` on a table that's been
      # explicitly blacklisted because of its size.
      #
      # Even though this helper performs the update in batches to avoid
      # downtime, using it with tables with millions of rows still causes a
      # significant delay in the deploy process and is best avoided.
      #
      # See https://gitlab.com/gitlab-com/infrastructure/issues/1602 for more
      # information.
      class AddColumnWithDefaultToLargeTable < RuboCop::Cop::Cop
        include MigrationHelpers

        MSG = 'Using `add_column_with_default` on the `%s` table will take a ' \
          'long time to complete, and should be avoided unless absolutely ' \
          'necessary'.freeze

        LARGE_TABLES = %i[
          events
          issues
          merge_requests
          namespaces
          notes
          projects
          routes
          users
        ].freeze

        def_node_matcher :add_column_with_default?, <<~PATTERN
          (send nil :add_column_with_default $(sym ...) ...)
        PATTERN

        def on_send(node)
          return unless in_migration?(node)

          matched = add_column_with_default?(node)
          return unless matched

          table = matched.to_a.first
          return unless LARGE_TABLES.include?(table)

          add_offense(node, :expression, format(MSG, table))
        end
      end
    end
  end
end

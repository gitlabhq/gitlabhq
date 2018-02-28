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
      class UpdateLargeTable < RuboCop::Cop::Cop
        include MigrationHelpers

        MSG = 'Using `%s` on the `%s` table will take a long time to ' \
              'complete, and should be avoided unless absolutely ' \
              'necessary'.freeze

        LARGE_TABLES = %i[
          ci_pipelines
          ci_builds
          events
          issues
          merge_request_diff_files
          merge_request_diffs
          merge_requests
          namespaces
          notes
          projects
          routes
          users
        ].freeze

        def_node_matcher :batch_update?, <<~PATTERN
          (send nil? ${:add_column_with_default :update_column_in_batches} $(sym ...) ...)
        PATTERN

        def on_send(node)
          return unless in_migration?(node)

          matches = batch_update?(node)
          return unless matches

          update_method = matches.first
          table = matches.last.to_a.first

          return unless LARGE_TABLES.include?(table)

          add_offense(node, location: :expression, message: format(MSG, update_method, table))
        end
      end
    end
  end
end

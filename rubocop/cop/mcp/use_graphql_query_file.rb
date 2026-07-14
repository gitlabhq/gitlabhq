# frozen_string_literal: true

module RuboCop
  module Cop
    module Mcp
      # Checks that MCP tool GraphQL operations are loaded from a `.graphql` file
      # via `load_graphql(...)` instead of being defined as an inline string or
      # HEREDOC in `register_version`.
      #
      # Operations stored under `app/graphql/queries/mcp/` are validated against
      # `GitlabSchema` at build time by `spec/graphql/all_queries_spec.rb`. An
      # inline operation silently skips that validation, allowing a query to drift
      # from the schema undetected.
      #
      # @example
      #
      #   # bad
      #   register_version VERSIONS[:v0_1_0], {
      #     operation_name: 'createNote',
      #     graphql_operation: <<~GRAPHQL
      #       mutation CreateNote($input: CreateNoteInput!) {
      #         createNote(input: $input) { errors }
      #       }
      #     GRAPHQL
      #   }
      #
      #   # good
      #   register_version VERSIONS[:v0_1_0], {
      #     operation_name: 'createNote',
      #     graphql_operation: load_graphql('work_items/create_note.mutation.graphql')
      #   }
      class UseGraphqlQueryFile < RuboCop::Cop::Base
        MSG = 'Load MCP tool GraphQL operations from a .graphql file under ' \
          'app/graphql/queries/mcp/ via load_graphql(...) instead of an inline ' \
          'string, so they are validated against GitlabSchema at build time. ' \
          'See https://gitlab.com/gitlab-org/gitlab/-/issues/603389.'

        # @!method inline_graphql_operation?(node)
        def_node_matcher :inline_graphql_operation?, <<~PATTERN
          (pair (sym :graphql_operation) {str dstr})
        PATTERN

        def on_pair(node)
          return unless inline_graphql_operation?(node)

          add_offense(node.value)
        end
      end
    end
  end
end

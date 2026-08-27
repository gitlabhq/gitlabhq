# frozen_string_literal: true

module Mcp
  module Tools
    module Commits
      class ListCommitsService < Base::GraphqlService
        register_version '0.1.0', {
          description: 'List commits in a GitLab project, filtered by ref, author, path, or date. ' \
            'Identify the project with exactly one of url or project_id. Returns compact commit ' \
            'metadata; use get_commit for a single commit\'s diff or notes.',
          input_schema: {
            type: 'object',
            required: [],
            properties: {
              url: {
                type: 'string',
                description: 'GitLab URL of the project.'
              },
              project_id: {
                type: 'string',
                description: 'ID or full path of the project.'
              },

              ref_name: {
                type: 'string',
                description: 'Branch or tag to list commits from. Defaults to the project default branch.'
              },
              author: {
                type: 'string',
                description: 'Filter by commit author name or email.'
              },
              path: {
                type: 'string',
                description: 'Only return commits that touch this file path.'
              },
              since: {
                type: 'string',
                description: 'Only return commits with a committed date after this ISO 8601 date or time.'
              },
              until: {
                type: 'string',
                description: 'Only return commits with a committed date before this ISO 8601 date or time.'
              },
              order: {
                type: 'string',
                description: 'Ordering strategy. Defaults to reverse chronological when omitted.',
                # Source of truth is the CommitOrder GraphQL enum; a spec guards against drift.
                enum: %w[topo date]
              },
              first_parent: {
                type: 'boolean',
                description: 'Follow only the first parent of merge commits.'
              },
              with_stats: {
                type: 'boolean',
                description: 'Include per-commit line-count stats (additions, deletions, files changed). ' \
                  'Each commit costs a Gitaly call, so the page is capped at 10 when set: first defaults to 10 ' \
                  'and must not exceed 10.'
              },

              after: {
                type: 'string',
                description: 'Cursor for forward pagination. Use endCursor from the previous response.'
              },
              first: {
                type: 'integer',
                description: 'Number of commits to return (forward pagination, default 20, max 100). ' \
                  'A maximum of 10 applies when with_stats is set.',
                minimum: 1,
                maximum: 100
              }
            }
          },
          annotations: {
            readOnlyHint: true
          }
        }

        protected

        def graphql_tool_class
          Mcp::Tools::Commits::ListCommitsTool
        end

        def perform_v0_1_0(arguments)
          execute_graphql_tool(arguments)
        end

        override :perform_default
        def perform_default(arguments = {})
          perform_v0_1_0(arguments)
        end
      end
    end
  end
end

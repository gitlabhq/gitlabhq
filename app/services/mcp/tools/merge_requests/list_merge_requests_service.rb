# frozen_string_literal: true

module Mcp
  module Tools
    module MergeRequests
      class ListMergeRequestsService < Base::GraphqlService
        register_version '0.1.0', {
          description: 'List or search merge requests in a GitLab project by author, assignee, reviewer, ' \
            'state, milestone, labels, or text. Identify the project with exactly one of url or ' \
            'project_id. Returns compact merge request metadata; use get_merge_request for the full ' \
            'detail of a single merge request, or search for full-text search across resource types.',
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

              author_username: {
                type: 'string',
                description: 'Filter by the username of the merge request author.'
              },
              assignee_username: {
                type: 'string',
                description: 'Filter by the username of an assignee.'
              },
              reviewer_username: {
                type: 'string',
                description: 'Filter by the username of a reviewer.'
              },
              state: {
                type: 'string',
                description: 'Filter by merge request state. Omit to include merge requests in any state.',
                enum: %w[opened closed merged locked all]
              },
              scope: {
                type: 'string',
                description: 'Filter relative to the authenticated user, for requests such as ' \
                  '"my merge requests" or "merge requests awaiting my review". ' \
                  'created_by_me sets author_username, assigned_to_me sets assignee_username, ' \
                  'review_requested sets reviewer_username. ' \
                  'An explicit username wins for that field.',
                enum: %w[created_by_me assigned_to_me review_requested]
              },
              milestone: {
                type: 'string',
                description: 'Filter by the title of the milestone.'
              },
              labels: {
                type: 'string',
                description: 'Comma-separated list of label names. Only merge requests with all of ' \
                  'these labels are returned.'
              },
              search: {
                type: 'string',
                description: 'Search query matched against merge request title and description.'
              },

              after: {
                type: 'string',
                description: 'Cursor for forward pagination. Use endCursor from the previous response.'
              },
              first: {
                type: 'integer',
                description: 'Number of merge requests to return (forward pagination, default 20, max 100).',
                minimum: 1,
                maximum: 100
              }
            }
          },
          annotations: {
            readOnlyHint: true
          }
        }

        override :tool_aliases
        def self.tool_aliases
          ['gitlab_merge_request_search']
        end

        protected

        def graphql_tool_class
          Mcp::Tools::MergeRequests::ListMergeRequestsTool
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

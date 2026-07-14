# frozen_string_literal: true

module Mcp
  module Tools
    module MergeRequests
      class GetMergeRequestNotesService < Base::GraphqlService
        register_version '0.1.0', {
          description: 'Get the notes (comments and system notes) for a specific merge request.',
          input_schema: {
            type: 'object',
            required: [],
            properties: {
              url: {
                type: 'string',
                description: 'GitLab URL of the merge request. ' \
                  'Provide this, or project_id and merge_request_iid.'
              },
              project_id: {
                type: 'string',
                description: 'ID or path of the project. Required if url is not provided.'
              },
              merge_request_iid: {
                type: 'integer',
                description: 'Internal ID of the merge request. Required if url is not provided.'
              },
              after: {
                type: 'string',
                description: 'Cursor for forward pagination. Use endCursor from previous response.'
              },
              before: {
                type: 'string',
                description: 'Cursor for backward pagination. Use startCursor from previous response.'
              },
              first: {
                type: 'integer',
                description: 'Number of notes to return after the cursor (forward pagination, max 100)',
                minimum: 1,
                maximum: 100
              },
              last: {
                type: 'integer',
                description: 'Number of notes to return before the cursor (backward pagination, max 100)',
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
          Mcp::Tools::MergeRequests::GetMergeRequestNotesTool
        end

        def perform_0_1_0(arguments)
          execute_graphql_tool(arguments)
        end

        override :perform_default
        def perform_default(arguments = {})
          perform_0_1_0(arguments)
        end
      end
    end
  end
end

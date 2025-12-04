# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class GraphqlGetWorkItemNotesService < GraphqlService
        register_version '0.1.0', {
          description: 'Get all comments (notes) for a specific work item',
          input_schema: {
            type: 'object',
            properties: {
              # Work item identification (one set required)
              url: {
                type: 'string',
                description: 'GitLab URL for the work item.'
              },
              group_id: {
                type: 'string',
                description: 'ID or path of the group. Required if URL and project_id are not provided.'
              },
              project_id: {
                type: 'string',
                description: 'ID or path of the project. Required if URL and group_id are not provided.'
              },
              work_item_iid: {
                type: 'integer',
                description: 'Internal ID of the work item. Required if URL is not provided.'
              },

              # Pagination parameters
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
          }
        }

        protected

        def graphql_tool_class
          Mcp::Tools::WorkItems::GetWorkItemNotesTool
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

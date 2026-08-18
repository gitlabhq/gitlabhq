# frozen_string_literal: true

module Mcp
  module Tools
    module Wikis
      class ListWikiPagesService < Base::GraphqlService
        register_version '0.1.0', {
          description: 'List wiki pages in a GitLab project or group.',
          annotations: {
            readOnlyHint: true
          },
          input_schema: {
            type: 'object',
            properties: {
              project_id: {
                type: 'string',
                description: 'ID or path of the project. Required if group_id is not provided.'
              },
              group_id: {
                type: 'string',
                description: 'ID or path of the group. Required if project_id is not provided.'
              },
              first: {
                type: 'integer',
                minimum: 1,
                maximum: 100,
                description: 'Number of wiki pages to return after the cursor (forward pagination, max 100)'
              },
              after: {
                type: 'string',
                description: 'Cursor for forward pagination. Use endCursor from previous response.'
              }
            }
          }
        }

        protected

        def graphql_tool_class
          Mcp::Tools::Wikis::ListWikiPagesTool
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

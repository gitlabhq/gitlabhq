# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class GetWorkItemNotesService < Base::GraphqlService
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
              **Mcp::Tools::Concerns::CursorPagination.input_schema_params(
                items: 'notes',
                params: %i[first last after before],
                default_page_size: nil
              )
            }
          },
          annotations: {
            readOnlyHint: true
          }
        }

        protected

        def graphql_tool_class
          Mcp::Tools::WorkItems::GetWorkItemNotesTool
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

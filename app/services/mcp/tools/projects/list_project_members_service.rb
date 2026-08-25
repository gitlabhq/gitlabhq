# frozen_string_literal: true

module Mcp
  module Tools
    module Projects
      class ListProjectMembersService < Base::GraphqlService
        DEFAULT_PAGE_SIZE = ::Mcp::Tools::Projects::ListProjectMembersTool::DEFAULT_PAGE_SIZE
        MAX_PAGE_SIZE = ::Mcp::Tools::Projects::ListProjectMembersTool::MAX_PAGE_SIZE

        register_version '0.1.0', {
          description: 'List the members of a GitLab project with their role and access level. ' \
            'Direct members only, unless include_inherited is true.',
          input_schema: {
            type: 'object',
            required: %w[project_id],
            properties: {
              project_id: {
                type: 'string',
                description: 'ID or full path of the project'
              },
              include_inherited: {
                type: 'boolean',
                description: 'Include members inherited from parent groups. Defaults to false.'
              },
              query: {
                type: 'string',
                description: 'Filter by name or username.'
              },
              after: {
                type: 'string',
                description: 'Cursor for forward pagination. Use metadata.end_cursor from the ' \
                  'previous response.'
              },
              first: {
                type: 'integer',
                description: 'Number of members to return (forward pagination, default ' \
                  "#{DEFAULT_PAGE_SIZE}, max #{MAX_PAGE_SIZE}).",
                minimum: 1,
                maximum: MAX_PAGE_SIZE
              }
            }
          },
          annotations: {
            readOnlyHint: true
          }
        }

        protected

        def graphql_tool_class
          Mcp::Tools::Projects::ListProjectMembersTool
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

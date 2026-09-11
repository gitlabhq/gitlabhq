# frozen_string_literal: true

module Mcp
  module Tools
    module Projects
      class ListProjectMembersService < Base::GraphqlService
        register_version '0.1.0', {
          toolset: :core,
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
              **Mcp::Tools::Concerns::CursorPagination.input_schema_params(items: 'members', cursor_style: :metadata)
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

# frozen_string_literal: true

module Mcp
  module Tools
    module Projects
      class GetProjectService < Base::GraphqlService
        register_version '0.1.0', {
          description: 'Get metadata for a single GitLab project: numeric ID, full path, default ' \
            'branch, visibility, and web URL. Identify the project with exactly one of url or ' \
            'project_id. Use search with scope projects to find a project you cannot name yet.',
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
                description: 'Project ID or full path. Provide exactly one of url or project_id.'
              }
            }
          },
          annotations: {
            readOnlyHint: true
          }
        }

        protected

        def graphql_tool_class
          Mcp::Tools::Projects::GetProjectTool
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
